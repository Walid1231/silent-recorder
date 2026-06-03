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

    // Auto-fix plugins that are missing an AGP namespace (e.g. phone_state_background).
    // Also bump compileSdk for outdated plugins that ship with very low values.
    // Must be registered BEFORE evaluationDependsOn triggers evaluation.
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android =
                project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            if (android != null) {
                // Fix missing namespace
                if (android.namespace.isNullOrEmpty()) {
                    val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
                    if (manifest.exists()) {
                        val pkg = Regex("""package\s*=\s*"([^"]+)"""")
                            .find(manifest.readText())?.groupValues?.get(1)
                        if (pkg != null) {
                            android.namespace = pkg
                            logger.lifecycle("Auto-set namespace '$pkg' for :${project.name}")
                        }
                    }
                }
                // Fix outdated compileSdk (needed for android:attr/lStar in androidx.core)
                if (android.compileSdk == null || android.compileSdk!! < 34) {
                    android.compileSdk = 34
                    logger.lifecycle("Bumped compileSdk to 34 for :${project.name}")
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
