struct Vec(T, int size)
{
	T[size] a;
	
	alias this = a;
	
	T opBinary(string op : "*")(Vec!(T,size) b)
	{
		T sum = 0;
		static foreach(i; 0 .. size)
		{
			sum += a[i]*b[i];
		}
		return sum;
	}
	
	Vec!(T,size) opBinary(string op : "+")(Vec!(T,size) b)
	{
		Vec!(T,size) ret;
		static foreach(i; 0 .. size)
		{
			ret[i] = a[i]+b[i];
		}
		return ret;
	}
	
	this(T[size] b)
	{
		a = b;
	}
}

struct Quat(T)
{
	Vec!(T, 4) a;
	
	alias this = a;
	
	Quat!(T) opBinary(string op : "*")(Quat!(T) b)
	{
		Quat!(T) prod;
		prod[0] = a[0]*b[0]-a[1]*b[1]-a[2]*b[2]-a[3]*b[3];
		prod[1] = a[0]*b[1]+a[1]*b[0]+a[2]*b[3]-a[3]*b[2];
		prod[2] = a[0]*b[2]-a[1]*b[3]+a[2]*b[0]+a[3]*b[1];
		prod[3] = a[0]*b[3]+a[1]*b[2]-a[2]*b[1]+a[3]*b[0];
		return prod;
	}
	
	Quat!(T) opUnary(string s : "~")()
    {
        return [a[0],-a[1],-a[2],-a[3]];
    }
}

alias float2 = Vec!(float, 2);
alias float3 = Vec!(float, 3);
alias float4 = Vec!(float, 4);
alias floatq = Quat!(float);

alias double2 = Vec!(double, 2);
alias double3 = Vec!(double, 3);
alias double4 = Vec!(double, 4);
alias doubleq = Quat!(double);

alias int2 = Vec!(int, 2);
alias int3 = Vec!(int, 3);
alias int4 = Vec!(int, 4);

alias uint2 = Vec!(uint, 2);
alias uint3 = Vec!(uint, 3);
alias uint4 = Vec!(uint, 4);

struct Transform3D
{
	float3 position;
	floatq rotation;
	float3 scale;
}

struct Transform2D
{
	float2 position;
	float rotation;
	float2 scale;
}



