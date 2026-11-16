import {
  useEffect,
  useRef,
  type KeyboardEvent,
  type ReactNode,
} from 'react';
import { createPortal } from 'react-dom';

interface DialogSheetProps {
  /** Id of the element that names the dialog. */
  labelledBy: string;
  onClose: () => void;
  /** Extra classes for the dialog box, e.g. a fixed height. */
  className?: string;
  /** The head, scrolling body and pinned foot, laid out as a flex column. */
  children: ReactNode;
}

const FOCUSABLE =
  'button:not([disabled]), input:not([disabled]), select:not([disabled]), [href]';

const focusableIn = (root: HTMLElement) =>
  Array.from(root.querySelectorAll<HTMLElement>(FOCUSABLE));

/**
 * Stops the page behind from scrolling (iOS Safari scrolls it under a fixed
 * overlay otherwise). The scrollbar's width is padded back so the page does
 * not shift sideways on desktops that show one. Returns the undo.
 */
function lockPageScroll(): () => void {
  const root = document.documentElement;
  const { body } = document;
  const before = {
    rootOverflow: root.style.overflow,
    bodyOverflow: body.style.overflow,
    bodyPadding: body.style.paddingRight,
  };
  // clientWidth is 0 where there is no layout (jsdom); skip the padding there.
  const scrollbar = root.clientWidth > 0 ? window.innerWidth - root.clientWidth : 0;
  root.style.overflow = 'hidden';
  body.style.overflow = 'hidden';
  if (scrollbar > 0) {
    const padding = parseFloat(getComputedStyle(body).paddingRight) || 0;
    body.style.paddingRight = `${padding + scrollbar}px`;
  }
  return () => {
    root.style.overflow = before.rootOverflow;
    body.style.overflow = before.bodyOverflow;
    body.style.paddingRight = before.bodyPadding;
  };
}

/**
 * Modal shell: a bottom sheet below `sm`, a centered dialog from `sm`.
 * Escape closes, Tab stays inside, and focus returns to whatever opened it.
 * A control inside that handles Escape itself (clearing a search, cancelling
 * an edit) calls `preventDefault()`, and the dialog stays open.
 */
export function DialogSheet({
  labelledBy,
  onClose,
  className = '',
  children,
}: DialogSheetProps) {
  const dialogRef = useRef<HTMLDivElement>(null);
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;
  // Read while rendering: children focus themselves in their own effects,
  // which run before this component's.
  const openerRef = useRef<HTMLElement | null>(null);
  if (openerRef.current === null) {
    openerRef.current = document.activeElement as HTMLElement | null;
  }

  useEffect(() => lockPageScroll(), []);

  useEffect(() => {
    const opener = openerRef.current;
    function onKeyDown(event: globalThis.KeyboardEvent) {
      if (event.key === 'Escape' && !event.defaultPrevented && !event.isComposing) {
        onCloseRef.current();
      }
      // Focus can fall to <body> (a click on plain text, or any click in
      // Safari); Tab from there would walk the page behind the dialog.
      const dialog = dialogRef.current;
      if (event.key === 'Tab' && dialog && !dialog.contains(document.activeElement)) {
        const items = focusableIn(dialog);
        const target = event.shiftKey ? items[items.length - 1] : items[0];
        if (target) {
          event.preventDefault();
          target.focus();
        }
      }
    }
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      // The opener may be gone (adding a racer replaces its row).
      if (opener?.isConnected) opener.focus();
    };
  }, []);

  function trapTab(event: KeyboardEvent<HTMLDivElement>) {
    if (event.key !== 'Tab' || !dialogRef.current) return;
    const items = focusableIn(dialogRef.current);
    if (items.length === 0) return;
    const first = items[0];
    const last = items[items.length - 1];
    const active = document.activeElement;
    // The title takes focus but is not tabbable, so it counts as "before first".
    if (event.shiftKey && items.indexOf(active as HTMLElement) <= 0) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && active === last) {
      event.preventDefault();
      first.focus();
    }
  }

  return createPortal(
    <div className="fixed inset-0 z-40 flex items-end justify-center overscroll-contain bg-navy/50 sm:items-center sm:p-4">
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={labelledBy}
        onKeyDown={trapTab}
        className={`flex max-h-[90dvh] w-full flex-col rounded-t-2xl bg-white shadow-lg sm:max-w-lg sm:rounded-xl ${className}`.trim()}
      >
        {children}
      </div>
    </div>,
    document.body,
  );
}
