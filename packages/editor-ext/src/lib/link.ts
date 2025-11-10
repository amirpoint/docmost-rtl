import { mergeAttributes } from "@tiptap/core";
import TiptapLink from "@tiptap/extension-link";
import { Plugin } from "@tiptap/pm/state";
import { EditorView } from "@tiptap/pm/view";

export const LinkExtension = TiptapLink.extend({
  inclusive: false,

  parseHTML() {
    return [
      {
        tag: 'a[href]:not([data-type="button"]):not([href *= "javascript:" i])',
        getAttrs: (element) => {
          if (
            element
              .getAttribute("href")
              ?.toLowerCase()
              .startsWith("javascript:")
          ) {
            return false;
          }

          return null;
        },
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    if (HTMLAttributes.href?.toLowerCase().startsWith("javascript:")) {
      return [
        "a",
        mergeAttributes(
          this.options.HTMLAttributes,
          { ...HTMLAttributes, href: "" },
          { class: "link" },
        ),
        0,
      ];
    }

    // Check if the link is to help.smartx.ir subdomain
    const href = HTMLAttributes.href || "";
    const isHelpSmartxLink = href.includes("help.smartx.ir");

    // Add target="_blank" for external links (not help.smartx.ir)
    const linkAttributes = isHelpSmartxLink
      ? { class: "link" }
      : { class: "link", target: "_blank", rel: "noopener noreferrer" };

    return [
      "a",
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, linkAttributes),
      0,
    ];
  },

  addProseMirrorPlugins() {
    const { editor } = this;

    return [
      ...(this.parent?.() || []),
      new Plugin({
        props: {
          handleKeyDown: (view: EditorView, event: KeyboardEvent) => {
            const { selection } = editor.state;

            if (event.key === "Escape" && selection.empty !== true) {
              editor.commands.focus(selection.to, { scrollIntoView: false });
            }

            return false;
          },
        },
      }),
    ];
  },
});
