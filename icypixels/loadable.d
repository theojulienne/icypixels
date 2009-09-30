module icypixels.loadable;

version (Tango) {
    import tango.util.container.LinkedList;
    import tango.time.StopWatch;
} else {
    import std.date;
}

enum LoadState {
	Unloaded = 0,
	Loading = 1,
	Loaded = 2,
}

class Loadable {
	LoadState loadState = LoadState.Unloaded;
	
	void doLoad( ) {
		if ( loadState != LoadState.Unloaded )
			return;
		
		loadState = LoadState.Loading;
		
		load( );
		
		loadState = LoadState.Loaded;
	}
	
	abstract void load( ) {
		// subclasses will actually load the data here
	}
}

version (Tango) {
    alias LinkedList!(Loadable) LoadableList;
} else {
    
    class LoadableList {
        Loadable[] loadables;
        
        this( ) {
            
        }
        
        void add( Loadable l ) {
            loadables ~= l;
        }
        
        Loadable removeHead( ) {
            Loadable l = loadables[0];
            
            loadables = loadables[1..$].dup;
            
            return l;
        }
        
        int size( ) {
            return loadables.length;
        }
    }
    
    struct StopWatch {
        d_time start_time;
        
        void start( ) {
            start_time = getUTCtime( );
        }
        
        ulong microsec( ) {
            d_time curr_time = getUTCtime( );
            return (curr_time - start_time) * 1000000 / TicksPerSecond;
        }
    }
    
}

class ThreadedLoader {
	// because all our libraries, like SDL, completely
	// fail at multithreading, we're going to do a multitask
	// hack instead :(
	
	LoadableList toLoad;
	
	int numJobsTotal = 0;
	
	static ThreadedLoader _inst = null;
	static ThreadedLoader globalLoader( ) {
		if ( _inst is null ) {
			_inst = new ThreadedLoader;
		}
		return _inst;
	}
	
	this( ) {
		toLoad = new LoadableList;
		numJobsTotal = 0;
	}
	
	void queueObject( Loadable obj ) {
		toLoad.add( obj );
		numJobsTotal++;
	}
	
	void loadImmediate( Loadable obj ) {
		obj.doLoad( );
		numJobsTotal++;
	}
	
	double percentage( ) {
		int numCompletedJobs = numJobsTotal - toLoad.size;
		return cast(double)numCompletedJobs / cast(double)numJobsTotal;
	}
	
	
	void doWorkForTime( ulong microsec ) {
		StopWatch timer;
		timer.start;
		
		while ( toLoad.size > 0 && timer.microsec < microsec ) {
			Loadable obj = toLoad.removeHead;
			
			obj.doLoad;
		}
	}
}

