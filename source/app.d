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

bool CheckLayersVulkan(const(char)*[] targetLayers, VkLayerProperties* instanceLayers, uint instanceLayerCount)
{
    for (uint i = 0; i < targetLayers.length; i++) {
        bool found = false;

        for (uint j = 0; j < instanceLayerCount; j++) {
            if (!strcmp(instanceLayers[j].layerName.ptr, targetLayers[i])) {
                found = true;
                break;
            }
        }

        if (!found) {
            auto missingLayer = targetLayers[i];
            writefln("[I] layer %s not found!", missingLayer[0..strlen(missingLayer)]);
            return false;
        }
    }

    return true;
}

bool CheckExtensionsVulkan(const(char)*[] targetExtensions, VkExtensionProperties* instanceExtensions, uint instanceExtensionCount)
{
    for (uint i = 0; i < targetExtensions.length; i++) {
        bool found = false;

        for (uint j = 0; j < instanceExtensionCount; j++) {
            if (!strcmp(instanceExtensions[j].extensionName.ptr, targetExtensions[i])) {
                found = true;
                break;
            }
        }

        if (!found) {
            auto missingExtension = targetExtensions[i];
            writefln("[I] extension %s not found!", missingExtension[0..strlen(missingExtension)]);
            return false;
        }
    }

    return true;
}

void InitializeVulkan()
{
	loadGlobalLevelFunctions();
	
    const(char)*[] enabledLayers;

    uint instanceLayerCount;
    assert(!vkEnumerateInstanceLayerProperties(&instanceLayerCount, null));

    if (instanceLayerCount > 0) {
        auto instanceLayers = cast(VkLayerProperties*)malloc(VkLayerProperties.sizeof * instanceLayerCount);
        assert(!vkEnumerateInstanceLayerProperties(&instanceLayerCount, instanceLayers));
        // TODO: prettier logging for available layers 
        // for(uint i = 0; i < instanceLayerCount; i++) {
        //     auto instanceLayerName = instanceLayers[i].layerName;
        //     writefln("[I] available layer %s", instanceLayerName);
        // }

        const(char)*[1] instanceValidationLayers = [ "VK_LAYER_KHRONOS_validation" ];
        if (CheckLayersVulkan(instanceValidationLayers, instanceLayers, instanceLayerCount)) {
            enabledLayers ~= "VK_LAYER_KHRONOS_validation";
        } else {
            writeln("[I] khronos validation layers not found, skipping validation...");
        }

        free(instanceLayers);
    }
    
    const(char)*[] enabledExtensions;

    uint instanceExtensionCount;
    assert(!vkEnumerateInstanceExtensionProperties(null, &instanceExtensionCount, null));

    if (instanceExtensionCount > 0) {
        auto instanceExtensions = cast(VkExtensionProperties*)malloc(VkExtensionProperties.sizeof * instanceExtensionCount);
        assert(!vkEnumerateInstanceExtensionProperties(null, &instanceExtensionCount, instanceExtensions));

        uint requiredInstanceExtensionCount;
        auto requiredExtensions = glfwGetRequiredInstanceExtensions(&requiredInstanceExtensionCount);
        for (uint i = 0; i < requiredInstanceExtensionCount; i++) {
            enabledExtensions ~= requiredExtensions[i];
        }
        if (!CheckExtensionsVulkan(enabledExtensions, instanceExtensions, instanceExtensionCount)) {
            throw new Exception("required glfw extensions not present!");
        }

        const(char)*[1] instanceValidationExtensions = [ VK_EXT_DEBUG_REPORT_EXTENSION_NAME ];
        if (CheckExtensionsVulkan(instanceValidationExtensions, instanceExtensions, instanceExtensionCount)) {
            enabledExtensions ~= VK_EXT_DEBUG_REPORT_EXTENSION_NAME;
        } else {
            writeln("[I] debug report extension not found...");
        }

        free(instanceExtensions);
    } else {
        throw new Exception("required glfw extensions not present!");
    }

    const(VkApplicationInfo) applicationInfo = {
        sType: VK_STRUCTURE_TYPE_APPLICATION_INFO,
        pNext: null,
        pApplicationName: "cocreate",
        applicationVersion: 0,
        pEngineName: "cocreate",
        engineVersion: 0,
        apiVersion: VK_API_VERSION_1_0,
    };

    const(VkInstanceCreateInfo) instanceCreateInfo = {
        sType: VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        pNext: null,
        pApplicationInfo: &applicationInfo,
        enabledLayerCount: cast(uint)enabledLayers.length,
        ppEnabledLayerNames: cast(const(char*)*)enabledLayers,
        enabledExtensionCount: cast(uint)enabledExtensions.length,
        ppEnabledExtensionNames: cast(const(char*)*)enabledExtensions
    };

    VkInstance vkInstance;
    assert(!vkCreateInstance(&instanceCreateInfo, null, &vkInstance));

    loadInstanceLevelFunctions(vkInstance);

    VkPhysicalDevice vkPhysicalDevice;

    uint physicalDeviceCount;
    assert(!vkEnumeratePhysicalDevices(vkInstance, &physicalDeviceCount, null));

    if (physicalDeviceCount > 0) {
        auto physicalDevices = cast(VkPhysicalDevice*)malloc(VkPhysicalDevice.sizeof * physicalDeviceCount);
        assert(!vkEnumeratePhysicalDevices(vkInstance, &physicalDeviceCount, physicalDevices));
        
        vkPhysicalDevice = physicalDevices[0];

        free(physicalDevices);
    }

    uint physicalDeviceExtensionCount;
    assert(!vkEnumerateDeviceExtensionProperties(vkPhysicalDevice, null, &physicalDeviceExtensionCount, null));

    if (physicalDeviceExtensionCount > 0) {
        auto physicalDeviceExtensions = cast(VkExtensionProperties*)malloc(VkExtensionProperties.sizeof * physicalDeviceExtensionCount);
        assert(!vkEnumerateDeviceExtensionProperties(vkPhysicalDevice, null, &physicalDeviceExtensionCount, physicalDeviceExtensions));

        
        const(char)*[1] deviceSwapchainExtensions = [ VK_KHR_SWAPCHAIN_EXTENSION_NAME ];
        if (!CheckExtensionsVulkan(deviceSwapchainExtensions, physicalDeviceExtensions, physicalDeviceExtensionCount)) {
            throw new Exception("device does not have the required swapchain extension");
        }
    } else {
        throw new Exception("device has no extensions");
    }

    // TODO: make validation optional
    VkDebugReportCallbackCreateInfoEXT debugCallbackCreateInfo;
    debugCallbackCreateInfo.sType = VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT;
    debugCallbackCreateInfo.pNext = null;
    debugCallbackCreateInfo.flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
    

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
	
	glfwSwapInterval(1);
	
	InitializeVulkan();
	
	
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
