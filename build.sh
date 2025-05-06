#!/bin/bash
set -e

# デフォルト値の設定
PYTHON_VERSION="3.10.13"
OPENCV_VERSION="latest"
HEADLESS=1

# 引数の処理
while getopts "p:o:h:" opt; do
  case $opt in
    p) PYTHON_VERSION="$OPTARG" ;;
    o) OPENCV_VERSION="$OPTARG" ;;
    h) HEADLESS="$OPTARG" ;;
    *) echo "使用法: $0 [-p PYTHON_VERSION] [-o OPENCV_VERSION] [-h HEADLESS]"; exit 1 ;;
  esac
done

echo "ビルド設定:"
echo "- Python バージョン: $PYTHON_VERSION"
echo "- OpenCV バージョン: $OPENCV_VERSION"
echo "- Headless モード: $HEADLESS"

# Dockerイメージをビルド
echo "Dockerイメージをビルドしています..."
docker build -t opencv-python-builder \
  --build-arg PYTHON_VERSION=$PYTHON_VERSION \
  --build-arg OPENCV_VERSION=$OPENCV_VERSION \
  --build-arg OPENCV_HEADLESS=$HEADLESS .

# 一時コンテナを作成し実行する
echo "ビルドされたwhlファイルをコピーするために一時コンテナを起動します..."
CONTAINER_ID=$(docker run -d opencv-python-builder tail -f /dev/null)
mkdir -p ./dist

# whlファイルをコピーするためのコマンドを実行
echo "コンテナID: $CONTAINER_ID からwhlファイルをコピーします"
WHL_FILES=$(docker exec $CONTAINER_ID find /opt/opencv-python -name "*opencv*.whl" | tr '\n' ' ')
if [ -n "$WHL_FILES" ]; then
  for FILE in $WHL_FILES; do
    echo "コピー中: $FILE"
    docker cp $CONTAINER_ID:$FILE ./dist/
  done
else
  echo "whlファイルが見つかりませんでした"
fi

docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

ls -la ./dist/
