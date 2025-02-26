import std.stdio;
import glfw3.api;
import dgui;
import bindbc.opengl.util;
import game;
import erupted;
import erupted.vulkan_lib_loader;
import core.stdc.stdlib;
import core.stdc.string;
import vulkan;

extern(C) @nogc nothrow void errorCallback(int error, const(char)* description) {
	import core.stdc.stdio;
	fprintf(stderr, "Error: %s\n", description);
}

bool mouse_pending = false;
int mouse_button = 0;
int mouse_action = 0;
int mouse_x = 0;
int mouse_y = 0;

extern(C) @nogc nothrow void mouse_button_callback(GLFWwindow* window, int button, int action, int mods)
{
	double dxpos, dypos;
	glfwGetCursorPos(window, &dxpos, &dypos);
	mouse_x = cast(int)dxpos;
	mouse_y = cast(int)dypos;
	mouse_button = button;
	mouse_action = action;
	mouse_pending = true;
}



bool key_pending = false;
uint key_chr = 0;

extern(C) @nogc nothrow void text_callback(GLFWwindow* window, uint chr)
{
	key_pending = true;
	key_chr = chr;
}

extern(C) @nogc nothrow void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (key >= 256 && action == GLFW_PRESS)
	{
		key_pending = true;
        key_chr = -key;
	}
}



class MainApp : Panel
{
	this(Panel parent)
	{
		super(parent);
	}
	
	override void Draw()
	{
	
	}
	
}

MainApp app;

class GameWindow : Window
{
	this()
	{
		super();
	}
	
	override void Draw()
	{
	
	}
}

void main()
{
	glfwSetErrorCallback(&errorCallback);
	glfwInit();

    if (!glfwVulkanSupported()) {
        writeln("womp womp :c");
    }

	
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
	// glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
	// glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
	
	glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, 1);
	glfwWindowHint(GLFW_DECORATED, 0);
	window = glfwCreateWindow(1280, 720, "Cocreate", null, null);
	glfwSetMouseButtonCallback(window, &mouse_button_callback);
	glfwSetCharCallback(window, &text_callback);
	glfwSetKeyCallback(window, &key_callback);
	
	// glfwMakeContextCurrent(window);
    Vulkan.Initialize();

    VkSurfaceKHR windowSurface;
    glfwCreateWindowSurface(Vulkan.instance, window, null, cast(ulong*)windowSurface);

	
	// glfwSwapInterval(1);
	
	
	loadOpenGL();
	loadExtendedGLSymbol(cast(void**)&glBitmap, "glBitmap");
	
	mainpanel = new GameWindow();
	
	app = new MainApp(mainpanel);
	
	mainpanel.inner.destroy();
	mainpanel.inner = app;
	Game_Init();
	while (!glfwWindowShouldClose(window))
	{
		glfwPollEvents();
		
		if (mouse_pending)
		{
			DGUI_HandleMouse(mouse_x,mouse_y,mouse_button,mouse_action);
			mouse_pending = false;
		}
		
		if (key_pending)
		{
			DGUI_HandleKey(key_chr);
			key_pending = false;
		}

		int width, height;
		
		glEnable(GL_BLEND);
		glfwGetFramebufferSize(window, &width, &height);
		glViewport(0, 0, width, height);
		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		glClear(GL_COLOR_BUFFER_BIT);
		glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
		
		Game_Draw(width,height);
		DGUI_Draw(width,height);
		
		glfwSwapBuffers(window);
		
	}
	glfwTerminate();
}
