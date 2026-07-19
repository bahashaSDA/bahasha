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
    // Force a modern compileSdk on EVERY Android module, including third-party
    // plugins (e.g. reactive_ble_mobile) that still declare an older compileSdk;
    // their androidx deps require API 34+. This afterEvaluate MUST be registered
    // before evaluationDependsOn below forces the subproject to evaluate,
    // otherwise Gradle throws "already evaluated".
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileSdkVersion(35)
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
