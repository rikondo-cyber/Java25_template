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
project/
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   │       └── application.yml
│   └── test/
├── build.gradle
├── settings.gradle
├── Dockerfile
├── docker-compose.yml
└── .dockerignore
```

## セットアップ手順

### 1. 初期設定

**settings.gradle を作成:**
```groovy
rootProject.name = 'my-spring-app'
```

**src/main/resources/application.yml を配置**

### 2. Docker環境の起動

```bash
# すべてのサービスを起動
docker-compose up -d

# ログを確認
docker-compose logs -f app

# PostgreSQLのみ起動
docker-compose up -d postgres
```

### 3. アプリケーションへのアクセス

- アプリケーション: http://localhost:8080
- ヘルスチェック: http://localhost:8080/actuator/health
- PostgreSQL: localhost:5432

## 開発コマンド

### Docker操作

```bash
# ビルドして起動
docker-compose up --build

# 停止
docker-compose down

# ボリュームも削除して停止
docker-compose down -v

# 再ビルド
docker-compose build --no-cache
```

### Gradleコマンド（ローカル）

```bash
# ビルド
./gradlew build

# テスト実行
./gradlew test

# アプリケーション起動
./gradlew bootRun

# 依存関係の確認
./gradlew dependencies
```

### コンテナ内でのコマンド実行

```bash
# コンテナに入る
docker exec -it spring-boot-app sh

# ログ確認
docker logs spring-boot-app

# PostgreSQLに接続
docker exec -it postgres-db psql -U myuser -d mydb
```

## 環境変数のカスタマイズ

.env ファイルを作成して環境変数を管理:

```env
# Database
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword

# Application
SPRING_PROFILES_ACTIVE=dev
JAVA_OPTS=-Xmx512m -Xms256m
```

docker-compose.yml で読み込み:
```yaml
services:
  app:
    env_file:
      - .env
```

## 本番環境用の設定

### Dockerイメージのビルド

```bash
# イメージをビルド
docker build -t my-spring-app:latest .

# タグ付け
docker tag my-spring-app:latest registry.example.com/my-spring-app:1.0.0

# プッシュ
docker push registry.example.com/my-spring-app:1.0.0
```

### マルチステージビルドの利点

- ビルド依存関係を最終イメージに含めない
- イメージサイズの削減
- セキュリティの向上（JDKではなくJREを使用）

## トラブルシューティング

### ポートが既に使用されている

```bash
# 使用中のポートを確認
lsof -i :8080
netstat -ano | findstr :8080  # Windows

# docker-compose.yml のポートを変更
ports:
  - "8081:8080"
```

### ビルドエラー

```bash
# キャッシュをクリア
./gradlew clean
docker-compose down -v
docker-compose build --no-cache
```

### データベース接続エラー

```bash
# PostgreSQLの起動を確認
docker-compose ps

# 接続テスト
docker exec -it postgres-db psql -U myuser -d mydb

# アプリケーションのログを確認
docker-compose logs app
```

## カスタマイズポイント

1. **build.gradle**: 必要な依存関係を追加
2. **application.yml**: 環境に応じた設定
3. **docker-compose.yml**: サービスの追加（MongoDB、Elasticsearchなど）
4. **Dockerfile**: Java起動オプションの調整

## セキュリティのベストプラクティス

- 本番環境では環境変数やシークレット管理ツールを使用
- デフォルトのパスワードを変更
- 非rootユーザーでアプリケーションを実行
- 最小限の権限でコンテナを実行
- 定期的なイメージの更新

## その他のサービスの追加例

### MongoDB

```yaml
mongodb:
  image: mongo:7
  ports:
    - "27017:27017"
  environment:
    MONGO_INITDB_ROOT_USERNAME: admin
    MONGO_INITDB_ROOT_PASSWORD: password
```

### Elasticsearch

```yaml
elasticsearch:
  image: elasticsearch:8.11.0
  ports:
    - "9200:9200"
  environment:
    - discovery.type=single-node
```
