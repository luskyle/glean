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

// file_picker 等旧插件模块硬编码 compileSdk 34，而其传递依赖
// flutter_plugin_android_lifecycle 要求 36 —— 统一覆盖所有模块的 compileSdk。
// 用反射而非类型 API：AGP 版本差异大（9.x 已移除部分旧 DSL），最稳妥。
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val setter = androidExt.javaClass.methods.firstOrNull { m ->
            (m.name == "setCompileSdk" || m.name == "setCompileSdkVersion") &&
                m.parameterTypes.size == 1
        } ?: return@afterEvaluate
        try {
            setter.invoke(androidExt, 36)
        } catch (_: Exception) {
            // 模块未应用 AGP 或签名不匹配时静默跳过
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
