"""Aktivite arkadaşı ilanları — okey 4., tenis partneri vb."""
from __future__ import annotations

from datetime import datetime, timedelta

from content_filter import filter_profanity, profanity_ok
from feed_social import _ago
from models import ActivitySeek, ActivitySeekJoin, User

ACTIVITY_TYPES: dict[str, dict[str, str]] = {
    "okey": {"label": "Okey", "emoji": "🀄", "default_title": "4. oyuncu arıyorum"},
    "tennis": {"label": "Tenis", "emoji": "🎾", "default_title": "Tenis arkadaşı arıyorum"},
    "padel": {"label": "Padel", "emoji": "🏸", "default_title": "Padel partneri arıyorum"},
    "football": {"label": "Halı saha / Futbol", "emoji": "⚽", "default_title": "Oyuncu arıyorum"},
    "basketball": {"label": "Basketbol", "emoji": "🏀", "default_title": "Basketbol arkadaşı arıyorum"},
    "running": {"label": "Koşu", "emoji": "🏃", "default_title": "Koşu arkadaşı arıyorum"},
    "hiking": {"label": "Yürüyüş", "emoji": "🥾", "default_title": "Yürüyüş arkadaşı arıyorum"},
    "board": {"label": "Masa oyunu", "emoji": "🎲", "default_title": "Masa oyunu grubu arıyorum"},
    "other": {"label": "Diğer", "emoji": "✨", "default_title": "Arkadaş arıyorum"},
}

SKILL_LEVELS = {
    "any": "Fark etmez",
    "beginner": "Başlangıç",
    "intermediate": "Orta",
    "advanced": "İleri",
}


def activity_meta(key: str) -> dict[str, str]:
    return ACTIVITY_TYPES.get(key) or ACTIVITY_TYPES["other"]


def _join_count(seek: ActivitySeek) -> int:
    return sum(1 for j in seek.joins if j.status == "joined")


def _spots_left(seek: ActivitySeek) -> int:
    return max(0, int(seek.slots_needed or 1) - _join_count(seek))


def _refresh_status(seek: ActivitySeek) -> None:
    now = datetime.utcnow()
    if seek.status != "open":
        return
    if seek.expires_at and seek.expires_at <= now:
        seek.status = "expired"
        return
    if _spots_left(seek) <= 0:
        seek.status = "filled"


def list_open_seeks(db, *, activity_type: str | None = None, ilce: str | None = None, limit: int = 40):
    from sqlalchemy.orm import joinedload

    now = datetime.utcnow()
    q = (
        db.query(ActivitySeek)
        .options(joinedload(ActivitySeek.user), joinedload(ActivitySeek.joins).joinedload(ActivitySeekJoin.user))
        .filter(ActivitySeek.status == "open")
        .filter((ActivitySeek.expires_at.is_(None)) | (ActivitySeek.expires_at > now))
    )
    if activity_type and activity_type in ACTIVITY_TYPES:
        q = q.filter(ActivitySeek.activity_type == activity_type)
    if ilce:
        q = q.filter(ActivitySeek.ilce == ilce)
    rows = q.order_by(ActivitySeek.created_at.desc()).limit(max(1, min(limit, 80))).all()
    for row in rows:
        _refresh_status(row)
    db.commit()
    return [s for s in rows if s.status == "open"]


def seek_public(db, seek: ActivitySeek, viewer: User | None) -> dict:
    meta = activity_meta(seek.activity_type)
    host = seek.user
    joined_ids = {j.user_id for j in seek.joins if j.status == "joined"}
    spots_left = _spots_left(seek)
    viewer_joined = bool(viewer and viewer.id in joined_ids)
    viewer_host = bool(viewer and viewer.id == seek.user_id)
    joiners: list[dict] = []
    if viewer_joined or viewer_host:
        for j in seek.joins:
            if j.status != "joined" or not j.user:
                continue
            joiners.append(
                {
                    "id": j.user.id,
                    "name": j.user.display_name(),
                    "handle": j.user.handle(),
                    "avatar_url": j.user.avatar_url or "",
                }
            )
    out = {
        "id": seek.id,
        "activity_type": seek.activity_type,
        "activity_label": meta["label"],
        "emoji": meta["emoji"],
        "title": seek.title or meta["default_title"],
        "host": host.display_name() if host else "Üye",
        "host_id": seek.user_id,
        "host_handle": host.handle() if host else "",
        "ilce": seek.ilce or "",
        "venue": seek.venue or "",
        "time_label": seek.when_label or "Esnek",
        "when_at": seek.when_at.isoformat() if seek.when_at else None,
        "note": seek.note or "",
        "skill_level": seek.skill_level or "any",
        "skill_label": SKILL_LEVELS.get(seek.skill_level or "any", "Fark etmez"),
        "points_min": int(seek.points_min or 0),
        "slots_needed": int(seek.slots_needed or 1),
        "slots_filled": _join_count(seek),
        "spots_left": spots_left,
        "joiners_count": len(joined_ids),
        "joined": viewer_joined,
        "is_mine": viewer_host,
        "status": seek.status,
        "ago": _ago(seek.created_at),
        "contact_hint": "",
        "joiners": joiners,
    }
    if viewer_joined or viewer_host:
        out["contact_hint"] = seek.contact_hint or ""
    return out


def create_seek(db, user: User, payload: dict) -> tuple[ActivitySeek | None, str | None]:
    activity_type = (payload.get("activity_type") or payload.get("type") or "other").strip().lower()
    if activity_type not in ACTIVITY_TYPES:
        activity_type = "other"
    meta = activity_meta(activity_type)

    title = filter_profanity((payload.get("title") or meta["default_title"]).strip())[:120]
    note = filter_profanity((payload.get("note") or "").strip())[:800]
    venue = filter_profanity((payload.get("venue") or "").strip())[:160]
    contact_hint = filter_profanity((payload.get("contact_hint") or "").strip())[:120]
    when_label = filter_profanity((payload.get("when_label") or payload.get("time_label") or "Esnek").strip())[:80]
    ilce = (payload.get("ilce") or "").strip()[:48]

    if not profanity_ok(title) or not profanity_ok(note):
        return None, "Metin uygun değil"

    try:
        slots_needed = int(payload.get("slots_needed") or payload.get("slots") or 1)
    except (TypeError, ValueError):
        slots_needed = 1
    slots_needed = max(1, min(slots_needed, 10))

    try:
        points_min = int(payload.get("points_min") or 0)
    except (TypeError, ValueError):
        points_min = 0
    points_min = max(0, min(points_min, 5000))

    skill = (payload.get("skill_level") or "any").strip().lower()
    if skill not in SKILL_LEVELS:
        skill = "any"

    when_at = None
    raw_when = (payload.get("when_at") or "").strip()
    if raw_when:
        try:
            when_at = datetime.fromisoformat(raw_when.replace("Z", "+00:00").replace("+00:00", ""))
        except ValueError:
            when_at = None

    open_count = (
        db.query(ActivitySeek)
        .filter(ActivitySeek.user_id == user.id, ActivitySeek.status == "open")
        .count()
    )
    if open_count >= 5:
        return None, "En fazla 5 açık ilan olabilir"

    seek = ActivitySeek(
        user_id=user.id,
        activity_type=activity_type,
        title=title,
        slots_needed=slots_needed,
        ilce=ilce,
        venue=venue,
        when_label=when_label,
        when_at=when_at,
        note=note,
        skill_level=skill,
        points_min=points_min,
        contact_hint=contact_hint,
        status="open",
        expires_at=datetime.utcnow() + timedelta(days=7),
    )
    db.add(seek)
    db.commit()
    db.refresh(seek)
    return seek, None


def join_seek(db, user: User, seek_id: int) -> tuple[ActivitySeek | None, str | None]:
    seek = db.query(ActivitySeek).filter(ActivitySeek.id == seek_id).first()
    if seek is None:
        return None, "İlan bulunamadı"
    _refresh_status(seek)
    if seek.status != "open":
        return None, "İlan kapalı"

    if seek.user_id == user.id:
        return None, "Kendi ilanına katılamazsın"

    if int(user.loyalty_points or 0) < int(seek.points_min or 0):
        return None, f"En az {seek.points_min} puan gerekli"

    existing = (
        db.query(ActivitySeekJoin)
        .filter(ActivitySeekJoin.seek_id == seek.id, ActivitySeekJoin.user_id == user.id)
        .first()
    )
    if existing and existing.status == "joined":
        return None, "Zaten katıldın"

    if _spots_left(seek) <= 0:
        seek.status = "filled"
        db.commit()
        return None, "Kontenjan doldu"

    if existing:
        existing.status = "joined"
        existing.created_at = datetime.utcnow()
    else:
        db.add(ActivitySeekJoin(seek_id=seek.id, user_id=user.id, status="joined"))

    db.flush()
    _refresh_status(seek)
    db.commit()
    db.refresh(seek)
    return seek, None


def leave_seek(db, user: User, seek_id: int) -> tuple[ActivitySeek | None, str | None]:
    seek = db.query(ActivitySeek).filter(ActivitySeek.id == seek_id).first()
    if seek is None:
        return None, "İlan bulunamadı"

    row = (
        db.query(ActivitySeekJoin)
        .filter(ActivitySeekJoin.seek_id == seek.id, ActivitySeekJoin.user_id == user.id, ActivitySeekJoin.status == "joined")
        .first()
    )
    if row is None:
        return None, "Katılım yok"

    row.status = "left"
    if seek.status == "filled":
        seek.status = "open"
    db.commit()
    db.refresh(seek)
    return seek, None


def cancel_seek(db, user: User, seek_id: int) -> str | None:
    seek = db.query(ActivitySeek).filter(ActivitySeek.id == seek_id).first()
    if seek is None:
        return "İlan bulunamadı"
    if seek.user_id != user.id and user.role != "admin":
        return "Yetki yok"
    seek.status = "cancelled"
    db.commit()
    return None


def seed_demo_seeks(db) -> int:
    """Soğuk başlangıç — örnek ilanlar (yalnız tablo boşken)."""
    if db.query(ActivitySeek).count() > 0:
        return 0
    users = (
        db.query(User)
        .filter(User.is_active.is_(True), User.role == "user")
        .order_by(User.id.asc())
        .limit(6)
        .all()
    )
    if len(users) < 2:
        return 0
    samples = [
        ("okey", "Nilüfer", "Bu akşam 21:00", "3 kişiyiz, 1 kişi arıyoruz. Acele etmeyin :)", 1, 0),
        ("tennis", "Osmangazi", "Yarın 18:00", "Çiftler tenisi — partner arıyorum, orta seviye.", 1, 50),
        ("football", "Yıldırım", "Cumartesi 20:00", "Halı saha için 2 oyuncu lazım.", 2, 0),
        ("board", "Nilüfer", "Pazar 15:00", "Catan / Tabu — 2 kişi daha.", 2, 0),
    ]
    n = 0
    for i, (atype, ilce, when_label, note, slots, pts) in enumerate(samples):
        host = users[i % len(users)]
        meta = activity_meta(atype)
        db.add(
            ActivitySeek(
                user_id=host.id,
                activity_type=atype,
                title=meta["default_title"],
                slots_needed=slots,
                ilce=ilce,
                when_label=when_label,
                note=note,
                points_min=pts,
                status="open",
                expires_at=datetime.utcnow() + timedelta(days=5),
            )
        )
        n += 1
    db.commit()
    return n
