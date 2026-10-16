namespace ChirpOS.Core;

public sealed record PerchChoice(Surface Host,PerchEdge Edge,Box Screen,double Scale,double Lo,double Hi) {
    public bool IsSide=>Edge is PerchEdge.Left or PerchEdge.Right;
    public double Fraction(double coordinate) {
        if(IsSide)return (coordinate-Host.Rect.Y-42)/(Host.Rect.H-84);
        var rect=Edge==PerchEdge.Bottom?Geometry.BottomRect(Host,Screen):Host.Rect;
        var s=new Surface(Host.Id,rect);var start=Geometry.Foot(s,0).X;var end=Geometry.Foot(s,1).X;
        return (coordinate-start)/(end-start);
    }
    public V Foot(double coordinate)=>Geometry.Foot(Host,Fraction(coordinate),Edge,Scale,Screen);
}

public enum FlockPhase { Independent, Gathering, Dispersing }

// Social decisions share a simulation clock; each bird keeps its own animation clock.
public sealed class FlockCoordinator(double initialDelay=60) {
    public const int MaximumPerSpecies=2;
    public void PrepareFocusReactions(IReadOnlyList<Bird> residents,IReadOnlyList<Surface> surfaces,Func<double> random) {
        foreach(var host in surfaces.Where(s=>s.IsFocused)) {
            var waiting=residents.Where(b=>b.Host==host.Id && b.Edge==PerchEdge.Bottom && b.State!=BirdState.Flying && !b.Departing).ToArray();
            var delay=waiting.Select(b=>b.FocusReactionDelay??0).DefaultIfEmpty(0).Max();
            // Randomize who notices first, then reserve distinct takeoff times.
            foreach(var bird in waiting.Where(b=>b.FocusReactionDelay==null).OrderBy(_=>random()).ToArray()) {
                var unit=Math.Clamp(random(),0,1);delay+=.18+.32*unit+(unit>.85?.7:0);
                bird.ScheduleFocusReaction(delay);
            }
        }
    }
    public static bool CanAdmit(string id,IReadOnlyList<Bird> residents)=>residents.Count(b=>b.Species.Id==id)<MaximumPerSpecies;
    public void CancelCompanion(){companion=null;}
    public FlockPhase Phase {get;private set;}=FlockPhase.Independent;
    public double Remaining {get;private set;}=initialDelay;
    (string Species,Guid Group,double Remaining)? companion;
    double companionDelay;
    Guid? gatheringGroup;
    public bool CompanionReady=>companion!=null && companionDelay<=0;
    public Bird? DepartureCandidate(IReadOnlyList<Bird> residents,bool force,double unit) {
        var eligible=residents.Where(b=>!b.Departing && (force || b.VisitAge>=(b.GroupId==null?20:45))).ToArray();
        var singles=eligible.Where(b=>b.GroupId==null).ToArray();var candidates=singles.Length>0?singles:eligible;
        return candidates.Length==0?null:candidates[Math.Min(candidates.Length-1,(int)(Math.Clamp(unit,0,1)*candidates.Length))];
    }
    public string ArrivalSpecies(string original,IReadOnlyList<Bird> residents) {
        if(companion is not {} pending || !CanAdmit(pending.Species,residents) || !residents.Any(b=>!b.Departing && b.GroupId==pending.Group)){companion=null;return original;}
        companionDelay=3;return pending.Species;
    }
    public void PrepareArrival(Bird bird,IReadOnlyList<Bird> residents) {
        if(companion is {} pending && bird.Species.Id==pending.Species && residents.Any(b=>!b.Departing && b.GroupId==pending.Group))bird.GroupId=pending.Group;
    }
    public void DidArrive(Bird bird,IReadOnlyList<Bird> residents,int capacity,double unit) {
        if(companion is {} pending && bird.GroupId==pending.Group){companion=null;return;}
        if(residents.Count(b=>b.Species.Id==bird.Species.Id)>=MaximumPerSpecies || Phase==FlockPhase.Dispersing || residents.Count(b=>!b.Departing)>=capacity || unit>=.3)return;
        var group=Guid.NewGuid();bird.GroupId=group;bird.LeadsGroup=true;companion=(bird.Species.Id,group,25);companionDelay=3;
    }
    public void Tick(double dt,IReadOnlyList<Bird> residents,Func<double> random) {
        var elapsed=Math.Max(0,dt);
        companionDelay-=elapsed;
        if(companion is {} pending)companion=pending.Remaining>elapsed && residents.Any(b=>!b.Departing && b.GroupId==pending.Group)?(pending.Species,pending.Group,pending.Remaining-elapsed):null;
        Remaining-=elapsed;if(Remaining>0)return;
        var birds=residents.Where(b=>!b.Departing).ToArray();
        switch(Phase) {
            case FlockPhase.Independent:
                Phase=FlockPhase.Gathering;Remaining=30+random()*25;
                var paired=birds.Where(a=>birds.Any(b=>b!=a && b.Species.Id==a.Species.Id)).ToArray();
                var mixed=paired.Length==0 && birds.Length>=2 && random()<.05;
                var candidates=paired.Length==0?(mixed?birds:[]):paired;
                if(candidates.Length==0){Phase=FlockPhase.Independent;Remaining=60+random()*60;return;}
                var leader=candidates[Math.Min(candidates.Length-1,(int)(random()*candidates.Length))];
                var group=leader.GroupId ?? Guid.NewGuid();leader.GroupId=group;leader.LeadsGroup=true;gatheringGroup=group;
                var followers=birds.Where(b=>b!=leader && (mixed || b.Species.Id==leader.Species.Id)).OrderBy(b=>b.GroupId==group?0:(b.Species.Id==leader.Species.Id?1:2)).Take(1).ToArray();
                for(var i=0;i<followers.Length;i++){followers[i].GroupId=group;followers[i].LeadsGroup=false;followers[i].ScheduleSocialMove(1+i*3+random()*2);}
                break;
            case FlockPhase.Gathering:
                Phase=FlockPhase.Dispersing;Remaining=20+random()*15;companion=null;
                var dispersing=birds.Where(b=>b.GroupId==gatheringGroup).ToArray();
                for(var i=0;i<dispersing.Length;i++){dispersing[i].GroupId=null;dispersing[i].LeadsGroup=false;dispersing[i].ScheduleSocialMove(.5+i*2+random());}
                break;
            case FlockPhase.Dispersing:
                Phase=FlockPhase.Independent;Remaining=60+random()*60;break;
        }
    }
    public (PerchChoice Choice,double Coordinate)? Choose(IReadOnlyList<PerchChoice> options,Bird bird,IReadOnlyList<Bird> residents,Func<double> random) {
        if(options.Count==0)return null;
        var choices=options.ToList();
        var peers=residents.Where(b=>b!=bird && !b.Departing && b.GroupId==bird.GroupId && b.Host!=null).ToArray();
        if(bird.GroupId!=null && (peers.FirstOrDefault(b=>b.LeadsGroup) ?? peers.FirstOrDefault()) is Bird peer) {
            var nearby=choices.Where(c=>c.Host.Id==peer.Host && c.Edge==peer.Edge).ToArray();
            if(nearby.Length>0) {
                var first=nearby[0];var peerScale=first.Scale*peer.Species.Scale/bird.Species.Scale;
                var point=Geometry.Foot(first.Host,peer.Fraction,peer.Edge,peerScale,peer.BottomViewport);
                var desired=(first.IsSide?point.Y:point.X)+(random()<.5?-1:1)*(58*Math.Max(first.Scale,peerScale)+24);
                var best=nearby.MinBy(c=>Math.Abs(Math.Clamp(desired,c.Lo,c.Hi)-desired))!;
                return (best,Math.Clamp(desired,best.Lo,best.Hi));
            }
        }
        if(Phase==FlockPhase.Dispersing) {
            var elsewhere=choices.Where(c=>c.Host.Id!=bird.Host).ToList();if(elsewhere.Count>0)choices=elsewhere;
            int Count(long id)=>residents.Count(b=>b!=bird && !b.Departing && b.Host==id);
            var least=choices.Min(c=>Count(c.Host.Id));choices=choices.Where(c=>Count(c.Host.Id)==least).ToList();
        }
        var total=choices.Sum(c=>c.Hi-c.Lo);if(total<=0)return null;
        var ticket=Math.Clamp(random(),0,Math.BitDecrement(1d))*total;
        foreach(var choice in choices){var length=choice.Hi-choice.Lo;if(ticket<length)return(choice,choice.Lo+ticket);ticket-=length;}
        return null;
    }
}
