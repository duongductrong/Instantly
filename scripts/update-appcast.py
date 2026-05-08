#!/usr/bin/env python3
"""
update-appcast.py - Maintains Sparkle appcast.xml
Usage: python3 scripts/update-appcast.py <version> <build_number> <dmg_path> <appcast_path> [signature] [release_notes_html]
"""

import sys
import os
import datetime
import xml.etree.ElementTree as ET
from xml.dom import minidom


def main():
    if len(sys.argv) < 5:
        print("Usage: update-appcast.py <version> <build_number> <dmg_path> <appcast_path> [signature] [release_notes_html]")
        sys.exit(1)

    version = sys.argv[1]
    build_number = sys.argv[2]
    dmg_path = sys.argv[3]
    appcast_path = sys.argv[4]
    signature = sys.argv[5] if len(sys.argv) > 5 else ""
    release_notes_html = sys.argv[6] if len(sys.argv) > 6 else ""

    dmg_size = os.path.getsize(dmg_path)
    dmg_url = f"https://github.com/duongductrong/Instantly/releases/download/v{version}/Instantly-v{version}.dmg"
    pub_date = datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S %z")

    # Sparkle namespace
    sparkle_ns = "http://www.andymatuschak.org/xml-namespaces/sparkle"
    ET.register_namespace("sparkle", sparkle_ns)

    if os.path.exists(appcast_path):
        tree = ET.parse(appcast_path)
        root = tree.getroot()
        channel = root.find("channel")
    else:
        root = ET.Element("rss", {"xmlns:sparkle": sparkle_ns, "version": "2.0"})
        channel = ET.SubElement(root, "channel")
        title = ET.SubElement(channel, "title")
        title.text = "Instantly Changelog"

    # Create new item
    item = ET.Element("item")

    title = ET.SubElement(item, "title")
    title.text = f"Version {version}"

    pub_date_el = ET.SubElement(item, "pubDate")
    pub_date_el.text = pub_date

    version_el = ET.SubElement(item, f"{{{sparkle_ns}}}version")
    version_el.text = build_number

    short_version_el = ET.SubElement(item, f"{{{sparkle_ns}}}shortVersionString")
    short_version_el.text = version

    if release_notes_html:
        description = ET.SubElement(item, "description")
        # ElementTree escapes HTML tags into XML entities.
        # Standard XML parsers (including Sparkle's NSXMLParser) automatically
        # unescape text nodes, so Sparkle receives raw HTML for rendering.
        # CDATA is not required for correct Sparkle behavior.
        description.text = release_notes_html

    enclosure_attrs = {
        "url": dmg_url,
        "length": str(dmg_size),
        "type": "application/x-apple-diskimage",
        f"{{{sparkle_ns}}}version": build_number,
    }
    if signature:
        enclosure_attrs[f"{{{sparkle_ns}}}edSignature"] = signature

    enclosure = ET.SubElement(item, "enclosure", enclosure_attrs)

    # Insert after title or at beginning of channel
    title_el = channel.find("title")
    if title_el is not None:
        idx = list(channel).index(title_el) + 1
        channel.insert(idx, item)
    else:
        channel.insert(0, item)

    # Keep only last 10 items
    items = channel.findall("item")
    for old_item in items[10:]:
        channel.remove(old_item)

    # Pretty print XML
    rough_string = ET.tostring(root, encoding="unicode")
    reparsed = minidom.parseString(rough_string)
    pretty = reparsed.toprettyxml(indent="  ")

    # Remove blank lines introduced by minidom
    lines = [line for line in pretty.splitlines() if line.strip()]
    pretty = "\n".join(lines)

    with open(appcast_path, "w", encoding="utf-8") as f:
        f.write(pretty)
        f.write("\n")

    print(f"Updated {appcast_path} with version {version} (build {build_number})")


if __name__ == "__main__":
    main()
