module icypixels.loadable;

import tango.util.container.LinkedList;
import tango.core.ThreadPool;
import tango.time.StopWatch;

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

alias LinkedList!(Loadable) LoadableList;

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

