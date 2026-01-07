# Spring Boot Docker環境

Java 25 LTS + Spring Boot + Gradle + Docker環境のテンプレートプロジェクト

## 技術スタック

- Java 25 LTS
- Spring Boot 4.0.1
- Gradle 9.2.1
- PostgreSQL 18.1
- Docker & Docker Compose

## プロジェクト構造

```
Java_template/
├── docker-compose.db.yml # DBのみ起動（IDE開発用）
├── docker-compose.dev.yml # 開発用（VS Code Dev Container / bootRun）
├── docker-compose.prod.yml # 本番用（jar起動）
├── Dockerfile # 本番用 multi-stage build
├── Dockerfile.dev # 開発用（Gradle + JDK）
├── .dockerignore
├── gradlew # Gradle Wrapper（Linux/Mac）
├── gradlew.bat # Gradle Wrapper（Windows）
├── gradle/
│ └── wrapper/
│ └── gradle-wrapper.properties
├── .devcontainer/
│ └── devcontainer.json # VS Code Dev Containers 設定
├── src/
│ └── main/
│ ├── java/
│ │ └── com/example/
│ │ ├── MySpringAppApplication.java
│ │ └── HelloController.java
│ └── resources/
│ ├── application.yml # 共通設定
│ └── application-dev.yml # 開発用設定
└── README.md
```

# Java Spring Boot Docker Template

このリポジトリは **3つの利用シナリオ**（IDE開発 / VS Code Dev Container開発 / 本番デプロイ）を想定したテンプレートです。  
それぞれ使う compose ファイルと起動方法が異なります。

---

## シナリオ1：IDEを使った開発（Eclipse / IntelliJ など）

**目的**：アプリはIDEから起動し、DBだけDockerで用意する  
**使うファイル**：`docker-compose.db.yml`

### 起動手順（DBのみ起動）
```bash
docker compose -f docker-compose.db.yml up -d
```

### 停止（DB停止）
```bash
docker compose -f docker-compose.db.yml down
```

### DB接続情報（IDE側の設定）

- **Host**: `localhost`
- **Port**: `5433`（※ compose で `5433:5432` にしているため）
- **DB**: `appdb`
- **User**: `appuser`
- **Password**: `apppass`

### アプリ起動（IDE側）

Eclipse / IntelliJ で Spring Boot を通常起動（Run/Debug）

**推奨**：`SPRING_PROFILES_ACTIVE=dev` をIDEの起動設定に入れる  
（`application-dev.yml` を使うため）

例：
```bash
SPRING_PROFILES_ACTIVE=dev
DB_HOST=localhost
DB_PORT=5433
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=apppass
```

---

## シナリオ2：VS Code + Dev Containers を使った開発

**目的**：ローカルに Java/Gradle を入れず、コンテナ内で開発・起動する（ホットリロード/bootRun）  
**使うファイル**：`docker-compose.dev.yml`

# 1. テンプレートをクローン
git clone https://github.com/yourname/java-spring-template.git my-new-project
cd my-new-project

# 2. Git履歴をクリーンアップ（テンプレートの履歴を削除）
rm -rf .git

# 3. 初期化スクリプト実行
chmod +x init-project.sh
./init-project.sh my-api com.mycompany.myapi 5434 8081
"Example: ./init-project.sh my-api com.mycompany.myapi 5434(default) 8081(default)"
左から順に、プロジェクト名、パッケージ名、DBポート(初期値5434)、APPポート(初期値8081)


# 4. 新しいGitリポジトリとして初期化
git init
git add .
git commit -m "Initial commit from template"


### 起動手順（VS Code 推奨）

1. VS Codeでこのリポジトリを開く
2. コマンドパレットから **Dev Containers: Reopen in Container**
3. 自動で `docker-compose.dev.yml` が立ち上がり、`bootRun` が走ります

### ターミナルで起動したい場合
```bash
docker compose -f docker-compose.dev.yml up --build
```

### 停止
```bash
docker compose -f docker-compose.dev.yml down
```

### 仕様（dev）

- `app` は `./gradlew bootRun` で起動（開発向け）
- ソースは `.:/workspace` でマウント（編集が即反映）
- Gradle キャッシュは `gradle-cache` volume に保存

---

## シナリオ3：本番デプロイ用（コンテナで起動）

**目的**：本番向けに jar をビルドして、軽量なランタイムイメージで起動する  
**使うファイル**：`docker-compose.prod.yml`（内部で `Dockerfile` を使用）

### 起動（ビルドして起動）
```bash
docker compose -f docker-compose.prod.yml up --build -d
```

### 停止
```bash
docker compose -f docker-compose.prod.yml down
```

### 仕様（prod）

- `Dockerfile` は multi-stage build
  - **build stage**: `./gradlew clean bootJar -x test`
  - **runtime stage**: `jre-alpine` + 非rootユーザーで `java -jar app.jar`
- `SPRING_PROFILES_ACTIVE=prod` で起動（compose 側で指定）

---

## 共通：アクセス先

- **API**: http://localhost:8080
- **Health**: http://localhost:8080/actuator/health
- **PostgreSQL**（IDEシナリオ時）: `localhost:5433`

---

## よく使うログ確認
```bash
# Dev環境
docker compose -f docker-compose.dev.yml logs -f app

# 本番環境
docker compose -f docker-compose.prod.yml logs -f app

# DBのみ
docker compose -f docker-compose.db.yml logs -f db
```
