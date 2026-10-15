namespace ChirpOS.Core;
public sealed class HoverTracker<T> where T:class {
    T? target;double started;
    public T? Update(T? hit,double now){if(hit==null){target=null;return null;}if(!ReferenceEquals(target,hit)){target=hit;started=now;}return now-started>=1?hit:null;}
}
