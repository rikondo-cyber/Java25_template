#!/bin/bash
# init-project.sh

PROJECT_NAME=$1
PACKAGE_NAME=$2
DB_PORT=${3:-5433}
APP_PORT=${4:-8080}

if [ -z "$PROJECT_NAME" ] || [ -z "$PACKAGE_NAME" ]; then
    echo "Usage: ./init-project.sh <project-name> <package-name> [db-port] [app-port]"
    echo "Example: ./init-project.sh my-api com.mycompany.myapi 5434 8081"
    exit 1
fi

echo "🚀 Initializing project: $PROJECT_NAME"
echo "================================================"

# settings.gradle作成
echo "📝 Creating settings.gradle..."
cat > settings.gradle << EOF
rootProject.name = '$PROJECT_NAME'
EOF

# build.gradle作成（groupを更新）
echo "📝 Creating build.gradle..."
COMPANY=$(echo $PACKAGE_NAME | cut -d. -f1-2)
cat > build.gradle << EOF
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.0.1'
    id 'io.spring.dependency-management' version '1.1.7'
}

group = '$COMPANY'
version = '0.0.1-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    
    runtimeOnly 'org.postgresql:postgresql'
    
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}

tasks.named('test') {
    useJUnitPlatform()
}
EOF

# パッケージディレクトリ作成
echo "📁 Creating package structure..."
PACKAGE_PATH=$(echo $PACKAGE_NAME | tr '.' '/')
mkdir -p src/main/java/$PACKAGE_PATH
mkdir -p src/test/java/$PACKAGE_PATH

# Applicationクラス作成
# ハイフンとアンダースコアを削除し、PascalCaseに変換
MAIN_CLASS=$(echo $PROJECT_NAME | sed 's/[-_.]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g')
MAIN_CLASS="${MAIN_CLASS}Application"

echo "📝 Creating main class: ${MAIN_CLASS}.java"

cat > src/main/java/$PACKAGE_PATH/${MAIN_CLASS}.java << EOF
package ${PACKAGE_NAME};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ${MAIN_CLASS} {
    public static void main(String[] args) {
        SpringApplication.run(${MAIN_CLASS}.class, args);
    }
}
EOF

# HelloController作成
cat > src/main/java/$PACKAGE_PATH/HelloController.java << EOF
package ${PACKAGE_NAME};

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello from ${PROJECT_NAME}!";
    }
}
EOF

# 古いサンプル削除
if [ -d "src/main/java/com/example" ]; then
    rm -rf src/main/java/com/example
fi

# application.ymlのプロジェクト名更新
echo "⚙️  Updating application.yml..."
sed -i.bak "s/name: my-spring-app/name: $PROJECT_NAME/g" src/main/resources/application.yml
rm -f src/main/resources/application.yml.bak

# docker-compose.dev.yml のポート更新
echo "🐳 Updating docker-compose.dev.yml..."
sed -i.bak "s/5433:5432/$DB_PORT:5432/g" docker-compose.dev.yml
sed -i.bak "s/8080:8080/$APP_PORT:8080/g" docker-compose.dev.yml
sed -i.bak "s/container_name: app-/container_name: ${PROJECT_NAME}-/g" docker-compose.dev.yml
rm -f docker-compose.dev.yml.bak

# docker-compose.db.yml のポート更新
sed -i.bak "s/5433:5432/$DB_PORT:5432/g" docker-compose.db.yml
sed -i.bak "s/container_name: app-/container_name: ${PROJECT_NAME}-/g" docker-compose.db.yml
rm -f docker-compose.db.yml.bak

# docker-compose.prod.yml のポート更新
sed -i.bak "s/8080:8080/$APP_PORT:8080/g" docker-compose.prod.yml
sed -i.bak "s/container_name: app-/container_name: ${PROJECT_NAME}-/g" docker-compose.prod.yml
rm -f docker-compose.prod.yml.bak

# .gitignoreがなければ作成
if [ ! -f ".gitignore" ]; then
    echo "📄 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Gradle
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar

# IDE
.idea/
.vscode/
*.iml
*.iws
*.ipr

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.local

# Logs
logs/
*.log

# Test
coverage/
test-results/
EOF
fi

# Git初期化
if [ -d ".git" ]; then
    echo "🗑️  Removing old git history..."
    rm -rf .git
fi

echo "🎯 Initializing new git repository..."
git init
git add .
git commit -m "Initial commit: $PROJECT_NAME from template"

echo ""
echo "================================================"
echo "✅ Project initialized successfully!"
echo "================================================"
echo "Project Name: $PROJECT_NAME"
echo "Package:      $PACKAGE_NAME"
echo "DB Port:      $DB_PORT"
echo "App Port:     $APP_PORT"
echo ""
echo "Next steps:"
echo "  1. Review and customize build.gradle if needed"
echo "  2. Start development environment:"
echo "     docker compose -f docker-compose.dev.yml up --build"
echo "  3. Access your API at http://localhost:$APP_PORT"
echo ""
echo "Happy coding! 🎉"
