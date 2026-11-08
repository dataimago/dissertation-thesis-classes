"""Shared profile loading for the CI checks (MIT; docs/house-class-spec.md section 6)."""
import pathlib
import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROFILES = ROOT / "profiles"


def _is_map(v):
    return isinstance(v, dict) and len(v) > 0


def merge(base, over):
    out = dict(base)
    for k, v in over.items():
        out[k] = merge(out[k], v) if _is_map(v) and _is_map(out.get(k)) else v
    return out


def load_yaml(path):
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_raw(pid, profiles_dir=PROFILES):
    return load_yaml(pathlib.Path(profiles_dir) / f"{pid}.yaml")


def load_resolved(pid, profiles_dir=PROFILES):
    """The profile with the house defaults merged in (what the generator compiles)."""
    house = load_raw("house", profiles_dir)
    if pid == "house":
        return house
    return merge(house, load_raw(pid, profiles_dir))


def flatten(d, prefix=""):
    out = {}
    for k, v in d.items():
        p = f"{prefix}.{k}" if prefix else k
        if _is_map(v):
            out.update(flatten(v, p))
        else:
            out[p] = v
    return out


def load_tests(pid, profiles_dir=PROFILES):
    p = pathlib.Path(profiles_dir) / f"{pid}.test.yaml"
    return load_yaml(p) if p.exists() else {}
