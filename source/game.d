import math;
import std.stdio;


class Script
{
	alias LuaRef = int;
	
	LuaRef scriptref;
	string path;
	void Tick()
	{
		
	}
}

abstract class Item3D
{
	ulong id;
	Transform3D t;
	Scene scene;
}

class Obj : Item3D
{
	Obj[] children;
	
	this(ulong id)
	{
		this.id = id;
	}

	void Tick()
	{
		
	}
}

class Visual : Item3D
{
	Visual[] children;
	
	this(ulong id)
	{
		this.id = id;
	}
	
	void Render()
	{
	
	}
}

class Scene
{
	ulong curObjectId = 0;
	ulong curVisualId = 0;
	Obj[] objects;
	Obj[ulong] idToObj;
	Visual[] visuals;
	Visual[ulong] idToVisual;
	
	//lua_State scriptVM;
	
	this()
	{
		//this.scriptVM = luaL_newstate();
	}
	
	Obj CreateObj(Obj parent)
	{
		Obj obj = new Obj(++curObjectId);
		if(parent is null)
		{
			objects ~= obj;
		}
		else
		{
			parent.children ~= obj;
		}
		idToObj[curObjectId] = obj;
		obj.scene = this;
		return obj;
	}
	
	Visual CreateObj(Visual parent)
	{
		Visual visual = new Visual(++curVisualId);
		if(parent is null)
		{
			visuals ~= visual;
		}
		else
		{
			parent.children ~= visual;
		}
		visualToObj[curVisualId] = visual;
		visual.scene = this;
		return visual;
	}
}

Scene mainscene;

void Game_Init()
{
	//loadLua();
	mainscene = new Scene();
	mainscene.CreateObj(null);
}

void Game_Draw(int w, int h)
{
	glLoadIdentity();
	
}