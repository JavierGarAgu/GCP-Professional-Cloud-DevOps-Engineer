import json
import datetime


def main(event, context):

    print("===================================")
    print("New batch uploaded")
    print("===================================")

    bucket = event.get("bucket")
    file_name = event.get("name")
    size = event.get("size")

    timestamp = datetime.datetime.utcnow().isoformat()

    print(f"Bucket: {bucket}")
    print(f"File: {file_name}")
    print(f"Size: {size} bytes")
    print(f"Time: {timestamp}")

    print("Batch received successfully")
    print("Processing job queued")

    return {
        "status": "success",
        "file": file_name
    }