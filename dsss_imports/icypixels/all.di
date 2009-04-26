module icypixels.all;

public {
	import icypixels.color;
	import icypixels.texture;
	import icypixels.util;
	import icypixels.window;
	import icypixels.primitives;
	import icypixels.model;
	import icypixels.vector;
}

version (build) {
    debug {
        pragma(link, "icypixels");
    } else {
        pragma(link, "icypixels");
    }
}
