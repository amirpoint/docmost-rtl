import { NodeViewProps, NodeViewWrapper } from "@tiptap/react";
import { useMemo, useState, useRef, useEffect } from "react";
import { getFileUrl } from "@/lib/config.ts";
import clsx from "clsx";

export default function VideoView(props: NodeViewProps) {
  const { node, selected } = props;
  const { src, width, align } = node.attrs;
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isShortVideo, setIsShortVideo] = useState(false);

  const alignClass = useMemo(() => {
    if (align === "left") return "alignLeft";
    if (align === "right") return "alignRight";
    if (align === "center") return "alignCenter";
    return "alignCenter";
  }, [align]);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const handleLoadedMetadata = () => {
      if (isFinite(video.duration) && video.duration < 30) {
        setIsShortVideo(true);
      } else {
        setIsShortVideo(false);
      }
    };

    video.addEventListener("loadedmetadata", handleLoadedMetadata);
    
    // Check if metadata is already loaded
    if (video.readyState >= 1) {
      handleLoadedMetadata();
    }

    return () => {
      video.removeEventListener("loadedmetadata", handleLoadedMetadata);
    };
  }, [src]);

  return (
    <NodeViewWrapper>
      <video
        ref={videoRef}
        preload="metadata"
        width={width || "100%"}
        controls={!isShortVideo}
        autoPlay={isShortVideo}
        loop={isShortVideo}
        muted={isShortVideo}
        playsInline={isShortVideo}
        src={getFileUrl(src)}
        className={clsx(selected ? "ProseMirror-selectednode" : "", alignClass)}
        style={{ display: "block" }}
      />
    </NodeViewWrapper>
  );
}
