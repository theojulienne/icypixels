module icypixels.color;

struct Color
{
	double r, g, b, a;
	
	static Color create( float r, float g, float b )
	{
		Color c;
		c.r = r;
		c.g = g;
		c.b = b;
		c.a = 1;
		return c;
	}
}
