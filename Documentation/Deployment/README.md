# How to use the IoT Deployment Provider

## Note
Please note, that the provider and its associated libraries are still under active development and any features and/or use cases might still be subject to change. Obviously, this also means that this project is not bug-free. If you noticed any, please reach out!

## Prerequisites
If you use a raspberry pi, please make sure you have the following things set up before using the IoT deployment provider on it:

 - The avahi daemon is up and running. For a guide on how to, see [here](https://www.raspberrypi.org/forums/viewtopic.php?t=267113) 
 - You setup a key-based ssh connection to the pi enabling remote calls with being prompted for a password
 - You setup the pi as a stand-alone WAP. For a guide on how to, refer to  the official raspberry pi docs.
 -  You can connect your IoT device to the network of your raspberry pi
 - You need to have at least the Swift 5.5/ Swift 5.6 toolchain installed on your raspberry pi. (This might be replaced by using docker in the future) 

## Setting up the provider
To allow the setup for custom user-defined actions and IoT devices, the IoT DP is a developed as a shared library that offers the `IoTDeploymentProvider`. 

Let's look at the following example to describe how the provider works and how one can set it up: Assume we have some [LIFX](https://www.lifx.com) smart lamps that are connected to our raspberry pi. We wrote a cool web service using [Apodini](https://github.com/Apodini/Apodini) that exposes among other, the functionality of the lights (e.g. on/off, control the brightness, etc.) via some endpoints. Now we want to deploy the web service to our raspberry pi using the IoT deployment provider.  

Internally the provider runs a [device discovery](https://github.com/hendesi/SwiftDeviceDiscovery) that searches for devices that publish services under the given identifier, e.g. raspberry pis. It is possible to define `PostDiscoveryActions`. These are user-defined actions that will be executed on the found devices are return an `Int` telling us how many results of the action were found. They can be customised by implementing their `run` method. It's possible to pass these actions to the `IoTDeploymentProvider`. 

This is what we are going to do. But first, we need to create our own `LifxPostDiscoveryAction`. It should check if there are any lifx devices connected to raspberry pi. Luckily, there is already a [library](https://github.com/PSchmiedmayer/Swift-NIO-LIFX) that searches for lifx devices, so all we need to do is to run this action remotely on the pi and count the results. So we're going to create a new project called `Swift-NIO-LIFX-Impl` where we will use the Swift-NIO-LIFX and the SwiftDeviceDiscovery library. You can checkout the code [here](https://github.com/Apodini/Swift-NIO-LIFX-Impl). The project needs two target, one containing the post discovery action and the other being the actual executable that calculates the results. 
The executable will be, for our use case, just a simple CLI program that runs the Swift-NIO-LIFX discovery and persists the results to disk.
In our other target, the action, we need to run the executable target and read the results from the written file. Keep in mind that the post discovery action is executed locally, so in the action we need to copy the project to the pi and run it there. We can do this by writing a script that we executing within the action. What the script does, is basically cloning, building and running the project on the pi and copy the result in the persisted file back to our local machine. 
If you interested in the details, feel free to check it out by yourself.


Now that we created the action, we can continue by making a new target called `LifxDeploymentOption`. This will be used to define a deployment option using `Apodini.Metadata`. The option specifies the deployment target and can be used in the web service to annotate handler or groups and associate them with the deployment target. To put it in another way, all handlers/groups that are not annotate, will not be accessible on the deployed web service. Since it will be directly associated with the deployment target, it makes sense to name it somewhat similar, we will name it `lifx`. In the next step, we import the created target to our web service and annotate all lifx related handlers with our new created meta data option, like this:
```
Text("Should not be visible")
    .metadata(
        DeploymentDevice(.lifx)
    )
```

Once we are done, we create a second target, this time executable, and call into `LifxDeploymentProvider`. This will be our actual deployment provider. To make it work, we need to import the `IoTDeploymentTarget`. The `IoTDeploymentProvider` we are about to initialise takes a couple of arguments. If you already sure about these and just want a static provider, you can just pass the hardcoded parameters, otherwise we would suggest using `SwiftArgumentParser` to allow some customization from the command line.
Beside that we need to also import our newly created `LifxDeploymentOption` target as well as the `LifxPostDiscoveryAction` package we created in the beginning.
After initializing the IoTDeploymentProvider property, we can call 
```
provider.registerAction(
    scope: .all, 
    action: LIFXDeviceDiscoveryAction.self, 
    option: .device(.lifx)
)
```
to register our self-written action. After that we can start the deployment with `provider.run()`. 
That's it! After we started the deployment, the IoT deployment provider should take care of the rest. Once the deployment is completed, the web service should be accessible under your pis ip address and the default port 8080. 

## Further customization

As you may noticed if you have checked out the [project](https://github.com/Apodini/Swift-NIO-LIFX-Impl) containing the example action, it is possible to access the configuration of the `DeviceDiscovery` in your post discovery action by using a property wrapper like:
```
@Configuration
var username: String
```
This grants access to predefined configuration properties such as `username` or `logger`
If you like to define custom configurations, you can do so by writing an extension somewhere in the library target of the project containing your action. 
```
public extension ConfigurationProperty {
/// A `ConfigurationProperty` for the deployment directory.
    static var deploymentDirectory = ConfigurationProperty("key_deploymentDirectory")
}
```
When defining your deployment provider, pass them to the initialiser by just adding :
```
additionalConfiguration: [
    .deploymentDirectory: "/usr/deployment"
]
```

## Final remarks
As mentioned in the beginning, this is still work in progress. So if you come across any bugs or feel like there is some important feature missing or you just have questions about the provider, please don't hesitate to reach out to me or Paul.  
