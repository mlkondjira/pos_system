allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Correction pour AGP 8+ : Injecter le namespace manquant pour les plugins obsolètes
    plugins.withType<com.android.build.gradle.BasePlugin> {
        project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            if (namespace == null) {
                namespace = when (project.name) {
                    "blue_thermal_printer" -> "id.kakzaki.blue_thermal_printer"
                    // Fallback pour d'autres plugins potentiellement problématiques
                    else -> project.group.toString()
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
