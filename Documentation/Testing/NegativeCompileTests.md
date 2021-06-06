# Negative Compile Tests

Apodini supports additional test vectors, enabling us to verify that certain expressions
result in a compile time error, something you can't do with your standard testing framework.
Such testing is especially useful for the development of internal domain-specific languages using '@resultBuilder's.

Such tests targets are called **Negative Compile Tests**.
In those test targets you can place code that deliberately does not compile (while annotating what lines do not compile
and what compiler error is expected).
The `NegativeCompileTestsRunner` test target — a test target which integrates with the XCTest to boostrap the execution
of Negative Compile Tests — tries to build those Negative Compile Tests targets and checks the build output 
and build errors to the expected compiler errors.

## Defining a new Negative Compiler Tests Target

To add a new Negative Compile Test target you have to do two things:

1. Define a new SPM `.testTarget` inside your `Package.swift` (while adding the special `Cases` folder the list of excluded source files)
2. Configure your Target inside `NegativeCompileTestsRunner/configurations.swift` so the Runner knows about it.

So, step 1. would look like the following:
```swift
.testTarget(
    name: "ExampleTargetNegativeCompileTests",
    exclude: ["Cases"]
)
```

Step 2.:
```swift
let configurations: TestRunnerConfiguration = [
    .target(name: "ExampleTargetNegativeCompileTests")
]
```

Lastly you want to create two files inside your test target: the `Cases` folder and an empty source file in the root
of the target (preferably called `Empty.swift`; this is used to make the compiler stop complain about an empty target).

## Create Test Cases inside your Test Target

Once the target is set up, you can define your test cases inside the `Cases` folder, either by playing a source file
directly into the `Cases` folder, or by creating subdirectories.

You can then start writing source files which deliberately do not compile.
In order for the Runner to be able to validate that all of the expected compiler errors did in fact fire and that
nothing more than the expected compiler errors occurred, you need to declare each an every expected compiler error.


You do this by adding special comments above the line which contains the error.  
Adhere to the following format: `// error: <message>`.

An example compiler error declaration might look like the following:
```swift
var i = 0
// error: cannot find operator '++' in scope; did you mean '+= 1'?
i++
```

## Note to CI maintainers

The `NegativeCompileTestsRunner` is built around executing a `swift build` command and parsing the build output.
In order to avoid unnecessary recompilations (and sometimes `swift build` seemingly strips some build output if
compiling many files) the `swift build` should pass the same compiler arguments as the original compilation
the XCTest case was executed with (e.g. when doing `swift test -Xswiftc -DEXAMPLE` it defines the `EXAMPLE`
Active Compilation Flag and the `swift build` command executed within the runner should reflect those same flags).

We can't detect from within the runnable with which flags the file was compiled with.
Though we can cover the most used ones within our current CI setup.
Those are:

- If `DEBUG` is **not** set, we assume compilation was done in release configuration and therefore append `-c release`
- If run on linux platform we assume test discovery was enabled an append `--enable-test-discovery`
- When using the `--enable-code-coverage` flag we require that the Active Compilation Condition `COVERAGE` is also 
  set by supplying `-Xswiftc -DCOVERAGE`. When detecting `COVERAGE` we therefore
  append `--enable-code-coverage -Xswiftc -DCOVERAGE` 
