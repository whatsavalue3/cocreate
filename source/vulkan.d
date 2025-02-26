module vulkan;

import std.stdio;
import glfw3.api;
import erupted;
import erupted.vulkan_lib_loader;
import core.stdc.stdlib;
import core.stdc.string;

class Vulkan {
    static VkInstance instance;
    static VkPhysicalDevice physicalDevice;
    static VkDevice device;

    static bool CheckLayers(const(char)*[] targetLayers, VkLayerProperties* instanceLayers, uint instanceLayerCount)
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
    
    static bool CheckExtensions(const(char)*[] targetExtensions, VkExtensionProperties* instanceExtensions, uint instanceExtensionCount)
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

    static void Initialize() {
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
            if (CheckLayers(instanceValidationLayers, instanceLayers, instanceLayerCount)) {
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
            if (!CheckExtensions(enabledExtensions, instanceExtensions, instanceExtensionCount)) {
                throw new Exception("required glfw extensions not present!");
            }

            const(char)*[1] instanceValidationExtensions = [ VK_EXT_DEBUG_REPORT_EXTENSION_NAME ];
            if (CheckExtensions(instanceValidationExtensions, instanceExtensions, instanceExtensionCount)) {
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

        assert(!vkCreateInstance(&instanceCreateInfo, null, &this.instance));

        loadInstanceLevelFunctions(this.instance);

        VkPhysicalDevice vkPhysicalDevice;

        uint physicalDeviceCount;
        assert(!vkEnumeratePhysicalDevices(this.instance, &physicalDeviceCount, null));

        if (physicalDeviceCount > 0) {
            auto physicalDevices = cast(VkPhysicalDevice*)malloc(VkPhysicalDevice.sizeof * physicalDeviceCount);
            assert(!vkEnumeratePhysicalDevices(this.instance, &physicalDeviceCount, physicalDevices));
            
            // TODO: better gpu rating
            vkPhysicalDevice = physicalDevices[0];

            free(physicalDevices);
        }

        uint physicalDeviceExtensionCount;
        assert(!vkEnumerateDeviceExtensionProperties(vkPhysicalDevice, null, &physicalDeviceExtensionCount, null));

        if (physicalDeviceExtensionCount > 0) {
            auto physicalDeviceExtensions = cast(VkExtensionProperties*)malloc(VkExtensionProperties.sizeof * physicalDeviceExtensionCount);
            assert(!vkEnumerateDeviceExtensionProperties(vkPhysicalDevice, null, &physicalDeviceExtensionCount, physicalDeviceExtensions));

            
            const(char)*[1] deviceSwapchainExtensions = [ VK_KHR_SWAPCHAIN_EXTENSION_NAME ];
            if (!CheckExtensions(deviceSwapchainExtensions, physicalDeviceExtensions, physicalDeviceExtensionCount)) {
                throw new Exception("device does not have the required swapchain extension");
            }
        } else {
            throw new Exception("device has no extensions");
        }{

        // TODO: make validation optional
        VkDebugReportCallbackCreateInfoEXT debugCallbackCreateInfo;
        debugCallbackCreateInfo.sType = VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT;
        debugCallbackCreateInfo.pNext = null;
        debugCallbackCreateInfo.flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
    }
}
