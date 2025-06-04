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
    
    // Add compatibility settings for ML Kit packages and plugins
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        android.buildFeatures.apply {
            buildConfig = true
        }
        android.lint.apply {
            disable.add("UnsafeOptInUsageError")
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
