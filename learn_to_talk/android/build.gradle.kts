buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // Updated to latest stable version
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Force all dependencies to use our Kotlin version
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("1.9.22")
            }
        }
    }
    
    // Add compatibility settings for ML Kit packages and plugins
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        
        // Update compileSdk version for all plugins to match app's SDK version
        try {
            android.compileSdkVersion(35)
        } catch (e: Exception) {
            logger.warn("Failed to set compileSdkVersion for ${project.name}: ${e.message}")
        }
        
        android.buildFeatures.apply {
            buildConfig = true
        }
        
        android.lint.apply {
            disable.add("UnsafeOptInUsageError")
            // Disable resource validation for Google ML Kit plugins
            if (project.name.contains("google_mlkit") || project.path.contains("google_mlkit")) {
                disable.add("NewApi")
                abortOnError = false
                checkReleaseBuilds = false
            }
        }
        
        // Add special resource handling for Google ML Kit plugins
        if (project.name.contains("google_mlkit") || project.path.contains("google_mlkit")) {
            logger.lifecycle("Applying special resource fixes for ${project.name}")
            // Disable resource shrinking and validation for ML Kit plugins
            try {
                android.buildTypes.getByName("release").apply {
                    val shrinkMethod = this.javaClass.getMethod("setMinifyEnabled", Boolean::class.java)
                    shrinkMethod.invoke(this, false)
                }
            } catch (e: Exception) {
                logger.warn("Failed to disable minification for ${project.name}: ${e.message}")
            }
        }
        
        // Fix for missing namespace in plugins
        try {
            val namespaceMethod = android.javaClass.getMethod("getNamespace")
            val currentNamespace = namespaceMethod.invoke(android) as? String
            if (currentNamespace == null || currentNamespace.isEmpty()) {
                val projectPath = project.path.replace(":", ".")
                android.namespace = project.group.toString().takeIf { it.isNotEmpty() } ?: "com.example${projectPath}"
            }
        } catch (e: NoSuchMethodException) {
            // Namespace property doesn't exist, so we need to add it
            val projectPath = project.path.replace(":", ".")
            android.namespace = project.group.toString().takeIf { it.isNotEmpty() } ?: "com.example${projectPath}"
        }
        
        // Fix JVM compatibility issues for all plugins
        android.compileOptions.apply {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
        
        // Add Kotlin JVM target compatibility settings
        try {
            val kotlinExtension = project.extensions.findByName("kotlin") as? org.jetbrains.kotlin.gradle.dsl.KotlinJvmOptions
            kotlinExtension?.jvmTarget = JavaVersion.VERSION_17.toString()
        } catch (e: Exception) {
            // Kotlin extension not found or can't be cast
            logger.warn("Could not set Kotlin JVM target for ${project.name}: ${e.message}")
        }
        
        // Special handling for sound_stream plugin
        if (project.name == "sound_stream") {
            logger.lifecycle("Applying special JVM target fixes for sound_stream plugin")
            afterEvaluate {
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    kotlinOptions {
                        jvmTarget = JavaVersion.VERSION_17.toString()
                    }
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
