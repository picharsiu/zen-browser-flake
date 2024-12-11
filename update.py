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
    version: str
    aarch64: Variant
    generic: Variant
    specific: Variant


class Info(TypedDict):
    alpha: Channel
    beta: Channel
    twilight: Channel


def parse_version(url: str, channel: str) -> str:
    versions: list[dict[str, str]] | dict[str, str] = get(url).json()
    if isinstance(versions, dict):
        versions = [versions]
    return list(filter(
        lambda v: v["name"].lower().startswith(channel),
        versions        
    ))[0]["name"].split(" - ")[1].split(" (")[0]


def check_new_version(old_version: str, new_version: str, channel: str) -> bool:
    return (channel == "t" or old_version != new_version) and bool(compile(f"^[0-9]\\.[0-9]\\.[0-9]-{channel}\\.").match(new_version))


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



def main(info_file: str) -> None:
    with open(file=info_file, mode="r", encoding="utf-8") as f:
        info: Info = Info(**load(f))

    baseUrl: str = "https://api.github.com/repos/zen-browser/desktop/releases"
    
    alpha_version: str = parse_version(baseUrl, "alpha")
    new_alpha_version: bool = check_new_version(
        info["alpha"]["version"],
        alpha_version,
        "a"
    )
    beta_version: str = parse_version(baseUrl, "beta")
    new_beta_version: bool = check_new_version(
        info["beta"]["version"],
        beta_version,
        "b"
    )
    twilight_version: str = parse_version(f"{baseUrl}/tags/twilight", "twilight")
    new_twilight_version: bool = check_new_version(
        info["twilight"]["version"],
        twilight_version,
        "t"
    )

    if new_alpha_version:
        info = update_info("alpha", alpha_version, alpha_version, info)
    if new_beta_version:
        info = update_info("beta", beta_version, beta_version, info)
    if new_twilight_version:
        info = update_info("twilight", twilight_version, "twilight", info)

    if new_beta_version or new_beta_version or new_twilight_version:
        with open(file=info_file, mode="w", encoding="utf-8") as f:
            dump(info, f, indent=2)
    else:
        print("Zen Browser is up-to-date")

if __name__ == "__main__":
    main("./info.json")
