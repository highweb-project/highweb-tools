<%@ page language="java" contentType="text/html; charset=EUC-KR" pageEncoding="EUC-KR"%>
<!DOCTYPE html>
<html>
<head>
<title>WebCL Hello World</title>
<meta HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">

<style type="text/css">
.info {
    font-family: Arial, Helvetica, sans-serif;
    font-weight: bold;
    font-size: 14px;
    color: white;
    text-align: right;
}
</style>

<script>
var DATA_SIZE = 1024;

// Global data (moved out of main function so can access in clFinish callback),
// this should be moved to a UserData object.
var err;                                    // error code returned from API calls

var data = new Float32Array(DATA_SIZE);     // original data set given to device
var results = new Float32Array(DATA_SIZE);  // results returned from device
var count;                                  // number of inputs and results returned
var correct;                                // number of correct results returned

var cl;                                     // OpenCL context
var platforms;                              // array of compue platform ids
var platform;                               // compute platform id
var devices;                                // array of device ids
var device;                                 // compute device id
var context;                                // compute context
var queue;                                  // compute command queue
var program;                                // compute program
var kernel;                                 // compute kernel

var input;                                  // device memory used for the input array
var output;                                 // device memory used for the output array

var globalWorkSize = [];     // global domain size for our calculation
var localWorkSize = [];      // local domain size for our calculation
var gpu = true;

function InitCL()
{
    // Fill our data set with random float values
    count = DATA_SIZE;
    for(var i = 0; i < count; i++)
        data[i] = Math.random();

    try {
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.onreadystatechange = function() {
        	if(xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                var kernelSource;
        		kernelSource = xmlhttp.responseText;
        		if (kernelSource === null) {
                    console.error("No kernel named: " + "square");
                    return;
                }

        		try {
            		if(window.WebCL == undefined) {
                        console.error("webcl is yet to be undefined");
                        return null;
                    }

                    cl = webcl;
                    if(cl === null) {
                        console.error("No webcl object available");
                        return;
                    }
                    // Query for platforms supported by the machine.
                    platforms = cl.getPlatforms();
                    if(platforms.length === 0) {
                        console.error("No platforms available");
                        return;
                    }
                    platform = platforms[0];

                    // Connect to a compute device

                    //Choose default device
                    devices = platform.getDevices();

                    if(devices.length === 0)
                    {
                        console.error("No devices available");
                        return;
                    }
                    device = devices[0];

                    // Create a compute context
                    context = cl.createContext();
                    // Other way to create a webcl context is passing a property object.

                    // Create a command queue
                    queue = context.createCommandQueue(device, null);

            		program = context.createProgram(kernelSource);

                    // Build the program executable
                    program.build([device], "");

                    // Create the compute kernel in the program we wish to run
                    kernel = program.createKernel("square");

                    // Create the input and output arrays in device memory for our calculation
                    input = context.createBuffer(cl.MEM_READ_ONLY,  Float32Array.BYTES_PER_ELEMENT * count);
                    output = context.createBuffer( cl.MEM_WRITE_ONLY, Float32Array.BYTES_PER_ELEMENT * count);
                    if (input === null || output === null) {
                        console.error("Failed to allocate device memory");
                        return;
                    }

                    // Write our data set into the input array in device memory
                    queue.enqueueWriteBuffer( input, true, 0, Float32Array.BYTES_PER_ELEMENT * count, data, [] );

                    // Set the arguments to our compute kernel
                    kernel.setArg(0, input);
                    kernel.setArg(1, output);
                    kernel.setArg(2, new Uint32Array([count]));

                    // Get the maximum work group size for executing the kernel on the device
                    var workGroupSize = kernel.getWorkGroupInfo(device, cl.KERNEL_WORK_GROUP_SIZE);

                    globalWorkSize[0] = count;
                    localWorkSize[0] = workGroupSize;

                    // Execute the kernel over the entire range of our 1d input data set
                    // using the maximum number of work group items for this device
                    queue.enqueueNDRangeKernel(kernel, globalWorkSize.length, null, globalWorkSize, localWorkSize);

                    // Wait for the command queue to get serviced before reading back results
                    queue.finish();

                    // Read back the results from the device to verify the output
                    queue.enqueueReadBuffer(output, true, 0, Float32Array.BYTES_PER_ELEMENT * count, results, []);

                    // Validate our results (to 6 figure accuracy)
                    var TOINT = function(x) { return Math.floor(1000000 * x); };

                    correct = 0;
                    for(var i = 0; i < count; i++) {
                        if(TOINT(results[i]) === TOINT(data[i] * data[i]))
                            correct++;
                    }

                    // Print a brief summary detailing the results
                    var msg = "Computed " + correct + "/" + count + " correct values";
                    document.getElementById("msg").firstChild.nodeValue = msg;
        		} catch(e) {
        			console.error("Hello Example Failed 1 ; Message: "+ e.message);
        		}
        	}
        }

        xmlhttp.open("GET", "asset/new_file.cl", true);
        xmlhttp.send(null);

        // Shutdown and cleanup
    } catch (e) {
        console.error("Hello Example Failed 2 ; Message: "+ e.message);
    }
}
</script>
</head>

<body onload="InitCL()" bgcolor="black">
    <div style="position:absolute; left:0px; top:0px">
        <div class="info" style="position:absolute; left:10px; top:15px; width:40px;">Results:</div>
        <div id="msg" class="info" style="position:absolute; left:60px; top:15px; width:260px;">XX</div>
    </div>
</body>
</html>