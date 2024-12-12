#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3.pkgs.requests
from re import compile
from subprocess import run, PIPE
from json import loads, load, dump
from typing import TypedDict
from requests import get


class Variant(TypedDict):
    url: str
    hash: str


class Channel(TypedDict):        
    tag: str | None
    version: str
    aarch64: Variant
    generic: Variant
    specific: Variant


Info = dict[str, Channel]


def parse_version(url: str, channel: str) -> str:
    versions: list[dict[str, str]] | dict[str, str] = get(url).json()
    if isinstance(versions, dict):
        versions = [versions]
    return list(filter(
        lambda v: v["name"].lower().startswith(channel),
        versions        
    ))[0]["name"].split(" - ")[1].split(" (")[0]


def check_new_version(tag: str | None, channel: str, old_version: str, new_version: str) -> bool:
    return (tag is not None or old_version != new_version) \
        and bool(compile(f"^[0-9]\\.[0-9]\\.[0-9]-{channel}\\.").match(new_version))


def update_download(tag: str, variant: str, channel: Channel) -> Channel:
    url: str = f"https://github.com/zen-browser/desktop/releases/download/{tag}/zen.linux-{variant}.tar.bz2"
    channel[variant] = {
        "url": url,
        "hash": loads(run(
            ["nix", "store", "prefetch-file", url, "--log-format", "raw", "--json"], 
            stdout=PIPE
        ).stdout.decode("utf-8"))["hash"]
    }
    return channel


def update_info(channel: str, version: str, tag: str, info: Info) -> Info:
    print(f"Found new {channel} version: {version}! Prefetching...")
    info[channel]["version"] = version
    info[channel] = update_download(tag, "aarch64", info[channel])
    info[channel] = update_download(tag, "generic", info[channel])
    info[channel] = update_download(tag, "specific", info[channel])
    print("Done.")
    return info


def process_channel(info: Info, name: str, tag: str | None) -> bool:
    baseUrl: str = "https://api.github.com/repos/zen-browser/desktop/releases"
    version: str = parse_version(baseUrl, name)
    new_version: bool = check_new_version(
        tag,
        name[0],
        info[name]["version"],
        version,
    )
    if new_version:
        info = update_info(name, version, version if tag is None else tag, info)
    return new_version


def main(info_file: str) -> None:
    with open(file=info_file, mode="r", encoding="utf-8") as f:
        info: Info = Info(**load(f))

    if any(map(
        lambda c: process_channel(info, c[0], c[1].get("tag", None)), 
        info.items()
    )):
        with open(file=info_file, mode="w", encoding="utf-8") as f:
            dump(info, f, indent=2)
    else:
        print("Zen Browser is up-to-date")

if __name__ == "__main__":
    main("./info.json")
