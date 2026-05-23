"""Inspect paragraph spacing and text content in a PPTX slide."""
import sys
import zipfile
import xml.etree.ElementTree as ET


def fmt_spc(el):
    if el is None:
        return "none"
    for c in el:
        t = c.tag.split("}")[-1]
        if t == "spcPts":
            return str(c.get("val")) + "hpc(pts)"
        if t == "spcPct":
            return str(c.get("val")) + "(pct)"
    return "empty"


def main():
    slide_num = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    pptx_path = sys.argv[2] if len(sys.argv) > 2 else "assets/presentation.pptx"

    pptx = zipfile.ZipFile(pptx_path)
    data = pptx.read("ppt/slides/slide" + str(slide_num) + ".xml")
    root = ET.fromstring(data)

    txbodies = [el for el in root.iter() if el.tag.endswith("}txBody")]
    print("Slide " + str(slide_num) + ": " + str(len(txbodies)) + " txBody elements")

    for bi, body in enumerate(txbodies):
        paras = [c for c in body if c.tag.endswith("}p")]
        print("  Body " + str(bi) + ": " + str(len(paras)) + " paragraphs")
        for pi, para in enumerate(paras[:10]):
            pPr = next((c for c in para if c.tag.endswith("}pPr")), None)
            runs = [c for c in para if c.tag.endswith("}r")]
            text = "".join(
                (next((gc for gc in r if gc.tag.endswith("}t")), None) or ET.Element("x")).text or ""
                for r in runs
            )[:50]
            if pPr is None:
                print("    Para " + str(pi) + ": " + repr(text) + " | no pPr")
                continue
            spcBef = next((c for c in pPr if c.tag.endswith("}spcBef")), None)
            spcAft = next((c for c in pPr if c.tag.endswith("}spcAft")), None)
            lnSpc = next((c for c in pPr if c.tag.endswith("}lnSpc")), None)
            marL = pPr.get("marL")
            lvl = pPr.get("lvl")
            print(
                "    Para " + str(pi) + ": " + repr(text) +
                " | spcBef=" + fmt_spc(spcBef) +
                " spcAft=" + fmt_spc(spcAft) +
                " lnSpc=" + fmt_spc(lnSpc) +
                " marL=" + str(marL) +
                " lvl=" + str(lvl)
            )
        print()


if __name__ == "__main__":
    main()
