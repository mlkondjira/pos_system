allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ... votre code existant (plugins, etc) ...

subprojects {
    // Correctif pour la compatibilité de flutter_bluetooth_serial avec Android Gradle Plugin 8+
    if (project.name == "flutter_bluetooth_serial") {
        val applyFix = {
            val android = project.extensions.findByName("android")
            if (android != null && android is com.android.build.gradle.LibraryExtension) {
                android.namespace = "io.github.edufolly.flutterbluetoothserial"
            }
        }
        if (project.state.executed) {
            applyFix()
        } else {
            project.afterEvaluate { applyFix() }
        }
    }
}
