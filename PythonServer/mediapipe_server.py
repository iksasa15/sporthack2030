from flask import Flask, jsonify, request
import base64
import cv2
import mediapipe as mp
import numpy as np

app = Flask(__name__)

mp_pose = mp.solutions.pose
pose_detector = mp_pose.Pose(
    static_image_mode=True,
    model_complexity=1,
    min_detection_confidence=0.5,
)

mp_hands = mp.solutions.hands
hands_detector = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)


def decode_image():
    """Decode image from multipart file or base64 json payload."""
    if "image" in request.files:
        raw = request.files["image"].read()
        np_buffer = np.frombuffer(raw, dtype=np.uint8)
        return cv2.imdecode(np_buffer, cv2.IMREAD_COLOR)

    payload = request.get_json(silent=True) or {}
    image_base64 = payload.get("image_base64", "")
    if image_base64:
        if "," in image_base64:
            image_base64 = image_base64.split(",", 1)[1]
        raw = base64.b64decode(image_base64)
        np_buffer = np.frombuffer(raw, dtype=np.uint8)
        return cv2.imdecode(np_buffer, cv2.IMREAD_COLOR)

    return None


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/api/mediapipe/pose")
def mediapipe_pose():
    frame = decode_image()
    if frame is None:
        return jsonify({"error": "No valid image provided"}), 400

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    pose_result = pose_detector.process(rgb)
    hands_result = hands_detector.process(rgb)

    # ---- Pose response (existing contract) ----
    pose_payload = {"detected": False, "landmarks": [], "bbox": None}
    if pose_result.pose_landmarks:
        landmarks = []
        xs, ys = [], []
        for idx, lm in enumerate(pose_result.pose_landmarks.landmark):
            landmarks.append({
                "id": idx,
                "x": float(lm.x),
                "y": float(lm.y),
                "z": float(lm.z),
                "visibility": float(lm.visibility),
            })
            if lm.visibility > 0.2:
                xs.append(float(lm.x))
                ys.append(float(lm.y))

        bbox = None
        if xs and ys:
            bbox = {
                "x": min(xs),
                "y": min(ys),
                "width": max(xs) - min(xs),
                "height": max(ys) - min(ys),
            }

        pose_payload = {
            "detected": True,
            "landmarks": landmarks,
            "bbox": bbox,
        }

    # ---- Hands/fingers response (new) ----
    hands_payload = {"detected": False, "hands": []}
    if hands_result.multi_hand_landmarks:
        hand_entries = []
        handedness_list = hands_result.multi_handedness or []
        for hand_idx, hand_landmarks in enumerate(hands_result.multi_hand_landmarks):
            handedness = "unknown"
            score = 0.0
            if hand_idx < len(handedness_list):
                classification = handedness_list[hand_idx].classification[0]
                handedness = classification.label.lower()  # left / right
                score = float(classification.score)

            finger_landmarks = []
            xs, ys = [], []
            for idx, lm in enumerate(hand_landmarks.landmark):
                finger_landmarks.append({
                    "id": idx,
                    "x": float(lm.x),
                    "y": float(lm.y),
                    "z": float(lm.z),
                })
                xs.append(float(lm.x))
                ys.append(float(lm.y))

            bbox = {
                "x": min(xs),
                "y": min(ys),
                "width": max(xs) - min(xs),
                "height": max(ys) - min(ys),
            }

            hand_entries.append({
                "handedness": handedness,
                "score": score,
                "landmarks": finger_landmarks,
                "bbox": bbox,
            })

        hands_payload = {
            "detected": True,
            "hands": hand_entries,
        }

    return jsonify({
        "success": True,
        "pose": pose_payload,
        "hands": hands_payload,
    })


@app.post("/api/mediapipe/fingers")
def mediapipe_fingers():
    """
    Hand-only endpoint: returns only finger landmarks.
    This is useful for apps that only care about hands.
    """
    frame = decode_image()
    if frame is None:
        return jsonify({"error": "No valid image provided"}), 400

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    hands_result = hands_detector.process(rgb)

    if not hands_result.multi_hand_landmarks:
        return jsonify({"success": True, "hands": {"detected": False, "hands": []}})

    handedness_list = hands_result.multi_handedness or []
    hand_entries = []

    for hand_idx, hand_landmarks in enumerate(hands_result.multi_hand_landmarks):
        handedness = "unknown"
        score = 0.0
        if hand_idx < len(handedness_list):
            classification = handedness_list[hand_idx].classification[0]
            handedness = classification.label.lower()
            score = float(classification.score)

        landmarks = []
        xs, ys = [], []
        for idx, lm in enumerate(hand_landmarks.landmark):
            landmarks.append({
                "id": idx,
                "x": float(lm.x),
                "y": float(lm.y),
                "z": float(lm.z),
            })
            xs.append(float(lm.x))
            ys.append(float(lm.y))

        hand_entries.append({
            "handedness": handedness,
            "score": score,
            "landmarks": landmarks,
            "bbox": {
                "x": min(xs),
                "y": min(ys),
                "width": max(xs) - min(xs),
                "height": max(ys) - min(ys),
            },
        })

    return jsonify({
        "success": True,
        "hands": {
            "detected": True,
            "hands": hand_entries,
        },
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
