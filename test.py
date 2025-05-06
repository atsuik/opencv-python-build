import cv2
import numpy as np
import os

def test_h264_encoding():
    # 入力ファイルのパスを確認
    input_path = './sample/highway.mp4'
    if not os.path.exists(input_path):
        print(f"エラー: 入力ファイル {input_path} が見つかりません")
        return False

    # 出力ファイルのパス
    output_path = './sample/output.mp4'
    
    # 入力ビデオをオープン
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        print("エラー: ビデオファイルを開けませんでした")
        return False
    
    # ビデオのプロパティを取得
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    print(f"入力ビデオ情報: {width}x{height}, {fps}fps, {frame_count}フレーム")
    
    # H.264コーデックを指定
    fourcc = cv2.VideoWriter_fourcc(*'H264')
    # H.264が使用できない場合は、別のコーデックを試す
    if fourcc == 0:
        print("H264コーデックが利用できません。X264を試します。")
        fourcc = cv2.VideoWriter_fourcc(*'X264')
    if fourcc == 0:
        print("X264コーデックも利用できません。MPEG4を試します。")
        fourcc = cv2.VideoWriter_fourcc(*'XVID')
    
    # 出力ビデオライターを作成
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
    
    if not out.isOpened():
        print("エラー: 出力ビデオファイルを作成できませんでした")
        cap.release()
        return False
    
    print(f"エンコーディング開始...")
    
    # フレームごとに処理
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        # フレームを出力ビデオに書き込む
        out.write(frame)
        frame_count += 1
        
        if frame_count % 100 == 0:
            print(f"{frame_count}フレーム処理しました")
    
    # リソースを解放
    cap.release()
    out.release()
    
    print(f"処理完了: {frame_count}フレームを{output_path}に保存しました")
    
    # 出力ファイルが作成されたか確認
    if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
        print(f"成功: {output_path} が正常に作成されました")
        return True
    else:
        print(f"エラー: 出力ファイルの作成に失敗しました")
        return False

if __name__ == "__main__":
    print("OpenCVでH.264エンコーディングテストを実行します")
    print(f"OpenCVバージョン: {cv2.__version__}")
    
    result = test_h264_encoding()
    
    if result:
        print("テスト成功: H.264エンコーディングは使用可能です")
    else:
        print("テスト失敗: H.264エンコーディングに問題があります")
