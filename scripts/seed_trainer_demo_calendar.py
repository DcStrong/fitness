#!/usr/bin/env python3
"""Seed rich demo calendar data for trainer test@mail.ru."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from typing import Any

BASE = "http://localhost:3001"
TRAINER_EMAIL = "test@mail.ru"
TRAINER_PASSWORD = "fjghdk12"
STUDENT_PASSWORD = "fjghdk12"

STUDENTS = [
    ("anna.demo@mail.ru", "Анна"),
    ("ilya.demo@mail.ru", "Илья"),
    ("maria.demo@mail.ru", "Мария"),
    ("pavel.demo@mail.ru", "Павел"),
    ("olga.demo@mail.ru", "Ольга"),
]


def req(
    method: str,
    path: str,
    body: dict[str, Any] | None = None,
    token: str | None = None,
) -> Any:
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        f"{BASE}{path}",
        data=data,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read().decode()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        payload = error.read().decode()
        raise RuntimeError(f"{method} {path} -> {error.code}: {payload}") from error


def register_or_login(email: str, password: str, role: str) -> dict[str, Any]:
    try:
        return req(
            "POST",
            "/auth/register",
            {"email": email, "password": password, "role": role},
        )
    except RuntimeError:
        return req("POST", "/auth/login", {"email": email, "password": password})


def iso(dt: datetime) -> str:
    return (
        dt.astimezone(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def ensure_link(trainer_token: str, student_token: str) -> None:
    invite = req("POST", "/invitations", token=trainer_token)
    token = invite.get("token")
    if not token:
        raise RuntimeError(f"invitation missing token: {invite}")
    try:
        req("POST", "/invitations/accept", {"token": token}, token=student_token)
    except RuntimeError as error:
        message = str(error).lower()
        if "already" not in message and "409" not in message and "linked" not in message:
            raise


def create_slot(
    trainer_token: str, start: datetime, hours: int = 1, mode: str = "offline"
) -> dict[str, Any]:
    end = start + timedelta(hours=hours)
    return req(
        "POST",
        "/schedule/slots",
        {"startsAt": iso(start), "endsAt": iso(end), "mode": mode},
        token=trainer_token,
    )


def main() -> int:
    print("Logging in trainer…")
    trainer = register_or_login(TRAINER_EMAIL, TRAINER_PASSWORD, "trainer")
    trainer_token = trainer["accessToken"]
    coach_id = trainer["user"]["id"]
    print(f"Trainer id={coach_id}")

    print("Ensuring finance settings…")
    try:
        req(
            "PUT",
            "/finance/settings",
            {"defaultSessionPriceMinor": "150000", "currency": "RUB"},
            token=trainer_token,
        )
    except RuntimeError as error:
        print(f"finance settings note: {error}")

    linked: list[dict[str, str]] = []
    for email, label in STUDENTS:
        print(f"Prepare student {email}…")
        auth = register_or_login(email, STUDENT_PASSWORD, "student")
        ensure_link(trainer_token, auth["accessToken"])
        linked.append(
            {
                "email": email,
                "label": label,
                "token": auth["accessToken"],
                "id": auth["user"]["id"],
            }
        )

    now = datetime.now().astimezone()
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    created_slots = 0
    booked = 0
    pending = 0
    open_slots = 0

    # Past booked sessions
    for day_offset, hour, student_index, mode in [
        (-2, 10, 0, "offline"),
        (-2, 12, 1, "online"),
        (-1, 9, 2, "offline"),
        (-1, 15, 3, "online"),
        (0, 8, 4, "offline"),
    ]:
        start = today + timedelta(days=day_offset, hours=hour)
        if day_offset == 0 and start >= now:
            continue
        try:
            slot = create_slot(trainer_token, start, mode=mode)
            created_slots += 1
            student = linked[student_index]
            req(
                "POST",
                "/sessions",
                {"scheduleSlotId": slot["id"], "studentId": student["id"]},
                token=trainer_token,
            )
            booked += 1
        except RuntimeError as error:
            print(f"past book skip: {error}")

    # Upcoming confirmed sessions
    for day_offset, hour, student_index, mode in [
        (0, max(now.hour + 2, 11), 0, "online"),
        (0, max(now.hour + 4, 14), 1, "offline"),
        (1, 10, 2, "offline"),
        (1, 16, 3, "online"),
        (2, 9, 4, "offline"),
        (2, 13, 0, "online"),
        (3, 11, 1, "offline"),
        (4, 15, 2, "online"),
    ]:
        start = today + timedelta(days=day_offset, hours=hour)
        if start <= now:
            continue
        try:
            slot = create_slot(trainer_token, start, mode=mode)
            created_slots += 1
            student = linked[student_index % len(linked)]
            req(
                "POST",
                "/sessions",
                {"scheduleSlotId": slot["id"], "studentId": student["id"]},
                token=trainer_token,
            )
            booked += 1
        except RuntimeError as error:
            print(f"upcoming book skip: {error}")

    # Open free slots across the week
    for day_offset in range(0, 8):
        for hour in (9, 12, 15, 18):
            start = today + timedelta(days=day_offset, hours=hour)
            if start <= now + timedelta(hours=1):
                continue
            try:
                create_slot(
                    trainer_token,
                    start,
                    mode="online" if hour % 2 == 0 else "offline",
                )
                created_slots += 1
                open_slots += 1
            except RuntimeError:
                pass

    # Pending booking requests from different students
    for day_offset, hour, student_index in [
        (0, 19, 0),
        (1, 14, 1),
        (2, 17, 2),
        (4, 10, 3),
        (5, 12, 4),
    ]:
        start = today + timedelta(days=day_offset, hours=hour)
        if start <= now + timedelta(hours=2):
            start = (now + timedelta(hours=3 + student_index)).replace(
                minute=0, second=0, microsecond=0
            )
        try:
            slot = create_slot(
                trainer_token,
                start,
                mode="online" if student_index % 2 else "offline",
            )
            created_slots += 1
            student = linked[student_index]
            req(
                "POST",
                "/booking-requests",
                {"scheduleSlotId": slot["id"]},
                token=student["token"],
            )
            pending += 1
        except RuntimeError as error:
            print(f"pending skip: {error}")

    relationships = req("GET", "/relationships/me", token=trainer_token)
    slots = req("GET", "/schedule/slots", token=trainer_token)
    sessions = req("GET", "/sessions", token=trainer_token)
    inbox = req(
        "GET",
        "/booking-requests/inbox?status=pending&limit=50",
        token=trainer_token,
    )

    print("\n=== Demo seed summary ===")
    print(f"Trainer: {TRAINER_EMAIL}")
    rel_count = len(relationships) if isinstance(relationships, list) else relationships
    print(f"Linked students: {rel_count}")
    print(f"Slots total now: {len(slots) if isinstance(slots, list) else slots}")
    print(
        f"Sessions total now: {len(sessions) if isinstance(sessions, list) else sessions}"
    )
    print(f"Pending inbox: {inbox.get('total') if isinstance(inbox, dict) else inbox}")
    print(
        f"Created this run: slots≈{created_slots}, booked={booked}, "
        f"open≈{open_slots}, pending={pending}"
    )
    print("Demo student passwords: fjghdk12")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
