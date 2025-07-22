import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Anchor,
  Popover,
  Breadcrumbs,
  ActionIcon,
  Text,
  Tooltip,
} from "@mantine/core";
import { IconCornerDownRightDouble, IconDots } from "@tabler/icons-react";
import { Link, useParams } from "react-router-dom";
import classes from "@/features/page/components/breadcrumbs/breadcrumb.module.css";
import { SharedPageTreeNode } from "@/features/share/utils.ts";
import { buildSharedPageUrl } from "@/features/page/page.utils.ts";
import { extractPageSlugId } from "@/lib";
import { useMediaQuery } from "@mantine/hooks";
import { useTranslation } from "react-i18next";

interface SharedBreadcrumbProps {
  pageTree: SharedPageTreeNode[];
}

function getTitle(name: string, icon: string) {
  if (icon) {
    return `${icon} ${name}`;
  }
  return name || "untitled";
}

function findBreadcrumbPath(
  tree: SharedPageTreeNode[],
  pageSlugId: string,
  path: SharedPageTreeNode[] = [],
): SharedPageTreeNode[] | null {
  for (const node of tree) {
    if (node.slugId === pageSlugId) {
      return [...path, node];
    }

    if (node.children && node.children.length > 0) {
      const newPath = findBreadcrumbPath(node.children, pageSlugId, [
        ...path,
        node,
      ]);
      if (newPath) {
        return newPath;
      }
    }
  }
  return null;
}

export default function SharedBreadcrumb({ pageTree }: SharedBreadcrumbProps) {
  const { t } = useTranslation();
  const [breadcrumbNodes, setBreadcrumbNodes] = useState<
    SharedPageTreeNode[] | null
  >(null);
  const { pageSlug, shareId } = useParams();
  const isMobile = useMediaQuery("(max-width: 48em)");

  const currentPageSlugId = extractPageSlugId(pageSlug);

  useEffect(() => {
    if (pageTree?.length > 0 && currentPageSlugId) {
      const breadcrumb = findBreadcrumbPath(pageTree, currentPageSlugId);
      setBreadcrumbNodes(breadcrumb || null);
    }
  }, [currentPageSlugId, pageTree]);

  const HiddenNodesTooltipContent = () =>
    breadcrumbNodes?.slice(1, -1).map((node) => (
      <Button.Group orientation="vertical" key={node.id}>
        <Button
          justify="start"
          component={Link}
          to={buildSharedPageUrl({
            shareId: shareId,
            pageSlugId: node.slugId,
            pageTitle: node.name,
          })}
          variant="default"
          style={{ border: "none" }}
        >
          <Text fz={"sm"} className={classes.truncatedText}>
            {getTitle(node.name, node.icon)}
          </Text>
        </Button>
      </Button.Group>
    ));

  const MobileHiddenNodesTooltipContent = () =>
    breadcrumbNodes?.map((node) => (
      <Button.Group orientation="vertical" key={node.id}>
        <Button
          justify="start"
          component={Link}
          to={buildSharedPageUrl({
            shareId: shareId,
            pageSlugId: node.slugId,
            pageTitle: node.name,
          })}
          variant="default"
          style={{ border: "none" }}
        >
          <Text fz={"sm"} className={classes.truncatedText}>
            {getTitle(node.name, node.icon)}
          </Text>
        </Button>
      </Button.Group>
    ));

  const renderAnchor = useCallback(
    (node: SharedPageTreeNode) => (
      <Tooltip label={node.name || t("untitled")} key={node.id}>
        <Anchor
          component={Link}
          to={buildSharedPageUrl({
            shareId: shareId,
            pageSlugId: node.slugId,
            pageTitle: node.name,
          })}
          underline="never"
          fz="sm"
          key={node.id}
          className={classes.truncatedText}
        >
          {getTitle(node.name, node.icon)}
        </Anchor>
      </Tooltip>
    ),
    [shareId, t],
  );

  const getBreadcrumbItems = () => {
    if (!breadcrumbNodes) return [];

    if (breadcrumbNodes.length > 7) {
      const firstNode = breadcrumbNodes[0];
      const lastNode = breadcrumbNodes[breadcrumbNodes.length - 1];

      return [
        renderAnchor(firstNode),
        <Popover
          width={250}
          position="bottom"
          withArrow
          shadow="xl"
          key="hidden-nodes"
        >
          <Popover.Target>
            <ActionIcon color="gray" variant="transparent">
              <IconDots size={20} stroke={2} />
            </ActionIcon>
          </Popover.Target>
          <Popover.Dropdown>
            <HiddenNodesTooltipContent />
          </Popover.Dropdown>
        </Popover>,
        renderAnchor(lastNode),
      ];
    }

    return breadcrumbNodes.map(renderAnchor);
  };

  const getMobileBreadcrumbItems = () => {
    if (!breadcrumbNodes) return [];

    if (breadcrumbNodes.length > 0) {
      return [
        <Popover
          width={250}
          position="bottom"
          withArrow
          shadow="xl"
          key="mobile-hidden-nodes"
        >
          <Popover.Target>
            <Tooltip label="Breadcrumbs">
              <ActionIcon color="gray" variant="transparent">
                <IconCornerDownRightDouble size={20} stroke={2} />
              </ActionIcon>
            </Tooltip>
          </Popover.Target>
          <Popover.Dropdown>
            <MobileHiddenNodesTooltipContent />
          </Popover.Dropdown>
        </Popover>,
      ];
    }

    return breadcrumbNodes.map(renderAnchor);
  };

  return (
    <div className={classes.breadcrumbDiv}>
      {breadcrumbNodes && (
        <Breadcrumbs className={classes.breadcrumbs}>
          {isMobile ? getMobileBreadcrumbItems() : getBreadcrumbItems()}
        </Breadcrumbs>
      )}
    </div>
  );
} 