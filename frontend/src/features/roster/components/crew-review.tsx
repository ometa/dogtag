import {
  useEffect,
  useId,
  useRef,
  useState,
  type KeyboardEvent,
} from 'react';
import { EmailInput } from '@/components/inputs/email-input';
import { PhoneInput } from '@/components/inputs/phone-input';
import { ZipInput } from '@/components/inputs/zip-input';
import { Button } from '@/components/ui/button';
import { Field, Input } from '@/components/ui/field';
import type { PastRacer } from '@/features/roster/api/use-past-racers';
import type { PersonPayload } from '@/features/roster/api/use-person-mutations';
import { TickIcon } from '@/features/roster/components/tick-icon';
import {
  LINE_KEYS,
  applyFieldErrors,
  experienceNote,
  initialLines,
  isLineBlank,
  lineLabel,
  lineValue,
  missingMessage,
  unconfirmedCount,
  type LineKey,
  type LineState,
} from '@/features/roster/review';
import {
  draftFromPastRacer,
  payloadFromDraft,
  type PersonDraft,
} from '@/features/roster/utils';
import type { FieldErrors } from '@/lib/api-client';
import { t } from '@/locales/en';
import type { Race } from '@/types/api';

const selectClass =
  'block min-h-11 w-full rounded-md border border-flag bg-white px-3 py-2 font-sans text-base text-navy focus:outline-none focus-visible:ring-2 focus-visible:ring-link aria-[invalid=true]:border-star';

/** Reopens the lines the server rejected. */
export type ReportFieldErrors = (fieldErrors: FieldErrors) => void;

interface CrewReviewProps {
  titleId: string;
  racer: PastRacer;
  race: Race;
  /** 1-based position in the queue. */
  index: number;
  total: number;
  pending: boolean;
  /** Errors from a failed save that belong to no line (e.g. the team is full). */
  formErrors: string[];
  onSave: (payload: PersonPayload, reportFieldErrors: ReportFieldErrors) => void;
  onSkip: () => void;
  /** Absent when there is no list to go back to. */
  onBack?: () => void;
  onClose: () => void;
}

/** Step 2: the captain confirms each detail of one racer before saving. */
export function CrewReview({
  titleId,
  racer,
  race,
  index,
  total,
  pending,
  formErrors,
  onSave,
  onSkip,
  onBack,
  onClose,
}: CrewReviewProps) {
  const [draft, setDraft] = useState(() => draftFromPastRacer(racer, race));
  const [lines, setLines] = useState(() => initialLines(draft));
  const titleRef = useRef<HTMLHeadingElement>(null);
  const alertRef = useRef<HTMLDivElement>(null);
  // What a line held when Change opened it, so Escape can put it back.
  const beforeChange = useRef<Partial<Record<LineKey, BeforeChange>>>({});
  // Read out when Enter in a still-blank input cannot finish its line.
  const [notice, setNotice] = useState('');
  const errorText = formErrors.join('\n');

  useEffect(() => {
    titleRef.current?.focus();
  }, []);

  // The Add button disables while saving, so focus lands on the message
  // instead of dropping out of the dialog.
  useEffect(() => {
    if (errorText) alertRef.current?.focus();
  }, [errorText]);

  const firstName = draft.first_name.trim() || racer.first_name;
  const left = unconfirmedCount(lines);
  const setLine = (key: LineKey, state: Partial<LineState>) =>
    setLines((current) => ({ ...current, [key]: { ...current[key], ...state } }));

  /** False when the line is still blank and stays open. */
  function finishLine(key: LineKey, announce: boolean): boolean {
    if (isLineBlank(key, draft)) {
      const message = missingMessage(key);
      setLine(key, { confirmed: false, error: message });
      // The same text twice in a row is not read again, so vary it invisibly.
      if (announce) setNotice((now) => (now === message ? `${message}\u00a0` : message));
      return false;
    }
    delete beforeChange.current[key];
    setLine(key, { confirmed: true, editing: false, error: null });
    return true;
  }

  function changeLine(key: LineKey) {
    beforeChange.current[key] = {
      confirmed: lines[key].confirmed,
      values: Object.fromEntries(
        lineFields(key).map((field) => [field, draft[field]]),
      ),
    };
    setLine(key, { confirmed: false, editing: true });
  }

  /** Puts back a line opened with Change. False when there is nothing to go back to. */
  function cancelLine(key: LineKey): boolean {
    const before = beforeChange.current[key];
    if (!before) return false;
    delete beforeChange.current[key];
    setDraft((current) => ({ ...current, ...before.values }));
    setLine(key, { confirmed: before.confirmed, editing: false, error: null });
    return true;
  }

  return (
    <>
      {onBack && (
        <Button
          variant="ghost"
          className="-mb-3 ml-2.5 mt-1.5 self-start"
          disabled={pending}
          onClick={onBack}
        >
          {t('roster.backToList')}
        </Button>
      )}
      <div className="flex items-start justify-between gap-3 px-4 pb-2.5 pt-3.5">
        <div className="min-w-0">
          <h2
            id={titleId}
            ref={titleRef}
            tabIndex={-1}
            className="font-display text-[22px] font-semibold leading-tight [overflow-wrap:anywhere] focus:outline-none"
          >
            {t('roster.reviewTitle', {
              name: `${draft.first_name} ${draft.last_name}`.trim() || racer.email,
            })}
          </h2>
          {racer.last_raced_year && racer.last_team_name && (
            <p className="mt-0.5 text-sm text-navy/70 [overflow-wrap:anywhere]">
              {t('roster.lastRacedWith', {
                year: racer.last_raced_year,
                team: racer.last_team_name,
              })}
            </p>
          )}
        </div>
        <div className="-mt-2 flex shrink-0 items-center gap-1.5 whitespace-nowrap">
          <span className="text-sm font-semibold text-navy/70">
            {t('roster.reviewProgress', { index, total })}
          </span>
          <Button variant="ghost" disabled={pending} onClick={onClose}>
            {t('roster.close')}
          </Button>
        </div>
      </div>
      <div className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden overscroll-contain px-4">
        <div className="grid grid-cols-[minmax(0,1fr)] gap-2 pb-3.5">
          {LINE_KEYS.map((key) => (
            <ReviewLine
              key={key}
              lineKey={key}
              state={lines[key]}
              draft={draft}
              race={race}
              note={key === 'experience' ? experienceNote(racer, draft, race) : null}
              onDraft={(field, value) =>
                setDraft((current) => ({ ...current, [field]: value }))
              }
              onToggle={() =>
                setLines((current) => ({
                  ...current,
                  [key]: { ...current[key], confirmed: !current[key].confirmed },
                }))
              }
              onChange={() => changeLine(key)}
              onDone={(announce) => finishLine(key, announce)}
              onCancel={() => cancelLine(key)}
            />
          ))}
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-x-3.5 gap-y-1.5 border-t border-flag px-4 pb-4 pt-3">
        {formErrors.length > 0 && (
          <div
            ref={alertRef}
            role="alert"
            tabIndex={-1}
            className="basis-full rounded-md border border-star bg-white p-3 text-sm text-starText focus:outline-none focus-visible:ring-2 focus-visible:ring-link"
          >
            {formErrors.map((message) => (
              <p key={message}>{message}</p>
            ))}
          </div>
        )}
        <Button
          className="w-full sm:w-auto"
          disabled={left > 0}
          loading={pending}
          onClick={() => {
            // Keep focus in the dialog once this button disables.
            titleRef.current?.focus();
            onSave(payloadFromDraft(draft), (fieldErrors) =>
              setLines((current) => applyFieldErrors(current, fieldErrors)),
            );
          }}
        >
          {t('roster.addToTeam', { name: firstName })}
        </Button>
        <Button variant="ghost" disabled={pending} onClick={onSkip}>
          {t('roster.skip', { name: firstName })}
        </Button>
        <p role="status" className="sr-only">
          {notice}
        </p>
        <p aria-live="polite" className="m-0 basis-full text-sm text-navy/70">
          {left === 0
            ? t('roster.allConfirmed')
            : t(left === 1 ? 'roster.leftToConfirm_one' : 'roster.leftToConfirm_other', {
                count: left,
              })}
        </p>
      </div>
    </>
  );
}

interface BeforeChange {
  confirmed: boolean;
  values: Partial<PersonDraft>;
}

/** The draft fields a line edits. */
const lineFields = (key: LineKey): Array<keyof PersonDraft> =>
  key === 'name' ? ['first_name', 'last_name'] : [key];

/** "Change name", but "Change ZIP code" and "Change Instagram". */
const changeTarget = (key: LineKey, label: string) =>
  key === 'zipcode' || key === 'instagram' ? label : label.toLowerCase();

interface ReviewLineProps {
  lineKey: LineKey;
  state: LineState;
  draft: PersonDraft;
  race: Race;
  note: string | null;
  onDraft: (field: keyof PersonDraft, value: string) => void;
  onToggle: () => void;
  onChange: () => void;
  /** False when the line is still blank; `announce` reads that out. */
  onDone: (announce: boolean) => boolean;
  /** Escape in an open editor; false when the line cannot be put back. */
  onCancel: () => boolean;
}

/** One detail: a checkbox to confirm it, or its input while it is being changed. */
function ReviewLine({
  lineKey,
  state,
  draft,
  race,
  note,
  onDraft,
  onToggle,
  onChange,
  onDone,
  onCancel,
}: ReviewLineProps) {
  const label = lineLabel(lineKey);
  const noteId = useId();
  const checkboxRef = useRef<HTMLButtonElement>(null);
  const editorRef = useRef<HTMLDivElement>(null);
  const wasEditing = useRef(state.editing);
  const pressedDone = useRef(false);

  // Move focus along with the line: into its input when it opens (not on first
  // render, where the dialog title owns focus), back to its checkbox after Done.
  useEffect(() => {
    if (state.editing && !wasEditing.current) {
      editorRef.current?.querySelector<HTMLElement>('input, select')?.focus();
    } else if (!state.editing && pressedDone.current) {
      checkboxRef.current?.focus();
    }
    pressedDone.current = false;
    wasEditing.current = state.editing;
  }, [state.editing]);

  if (state.editing) {
    // From the Done button, a blank line sends focus to its empty input, which
    // reads its label and error. From Enter, focus is already there, so the
    // review reads the error out instead.
    const done = (via: 'button' | 'enter') => {
      pressedDone.current = true;
      if (onDone(via === 'enter')) return;
      pressedDone.current = false;
      if (via === 'button') {
        const controls = Array.from(
          editorRef.current?.querySelectorAll<HTMLInputElement | HTMLSelectElement>(
            'input, select',
          ) ?? [],
        );
        (controls.find((control) => !control.value.trim()) ?? controls[0])?.focus();
      }
    };
    return (
      <div
        ref={editorRef}
        onKeyDown={(event: KeyboardEvent<HTMLDivElement>) => {
          if (event.key === 'Enter' && event.target instanceof HTMLInputElement) {
            event.preventDefault();
            done('enter');
          }
          // Escape backs out of this change only; the dialog stays open.
          if (event.key === 'Escape' && !event.nativeEvent.isComposing) {
            pressedDone.current = true;
            if (onCancel()) event.preventDefault();
            else pressedDone.current = false;
          }
        }}
        className="grid gap-2.5 rounded-lg border border-link bg-white p-3"
      >
        <LineEditor
          lineKey={lineKey}
          draft={draft}
          race={race}
          error={state.error}
          onDraft={onDraft}
        />
        <Button variant="secondary" className="justify-self-start" onClick={() => done('button')}>
          {t('roster.done')}
        </Button>
      </div>
    );
  }

  const value = lineValue(lineKey, draft, race);
  return (
    <div
      className={`flex items-center gap-1 rounded-lg border pr-1.5 ${
        state.confirmed ? 'border-flag/50 bg-white' : 'border-flag bg-flag/30'
      }`}
    >
      <button
        ref={checkboxRef}
        type="button"
        role="checkbox"
        aria-checked={state.confirmed}
        aria-label={`${label}: ${value}`}
        aria-describedby={note ? noteId : undefined}
        onClick={onToggle}
        className="flex min-h-14 min-w-0 flex-1 items-center gap-3 rounded-lg py-1.5 pl-3 pr-1 text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-link"
      >
        <span
          className={`grid h-6 w-6 shrink-0 place-items-center rounded-full border-2 ${
            state.confirmed
              ? 'border-navy bg-navy text-white'
              : 'border-flag bg-white'
          }`}
        >
          {state.confirmed && <TickIcon />}
        </span>
        <span className="grid min-w-0 grid-cols-[minmax(0,1fr)]">
          <span className="text-[13px] text-navy/70">{label}</span>
          <span className="font-semibold [overflow-wrap:anywhere]">{value}</span>
          {note && (
            <span id={noteId} className="text-[13px] text-navy/70 [overflow-wrap:anywhere]">
              {note}
            </span>
          )}
        </span>
      </button>
      <Button
        variant="ghost"
        aria-label={t('roster.changeLabel', { label: changeTarget(lineKey, label) })}
        onClick={onChange}
      >
        {t('roster.change')}
      </Button>
    </div>
  );
}

interface LineEditorProps {
  lineKey: LineKey;
  draft: PersonDraft;
  race: Race;
  error: string | null;
  onDraft: (field: keyof PersonDraft, value: string) => void;
}

/** The input for one line, reusing the racer form's inputs. */
function LineEditor({ lineKey, draft, race, error, onDraft }: LineEditorProps) {
  const errors = error ? [error] : undefined;
  const nameErrorId = useId();

  switch (lineKey) {
    case 'name':
      return (
        <>
          <div className="grid gap-2.5 sm:grid-cols-2">
            <Field label={t('roster.firstName')} name="first_name">
              {(control) => (
                <Input
                  {...control}
                  autoComplete="off"
                  aria-invalid={error ? true : undefined}
                  aria-describedby={error ? nameErrorId : undefined}
                  value={draft.first_name}
                  onChange={(event) => onDraft('first_name', event.target.value)}
                />
              )}
            </Field>
            <Field label={t('roster.lastName')} name="last_name">
              {(control) => (
                <Input
                  {...control}
                  autoComplete="off"
                  aria-invalid={error ? true : undefined}
                  aria-describedby={error ? nameErrorId : undefined}
                  value={draft.last_name}
                  onChange={(event) => onDraft('last_name', event.target.value)}
                />
              )}
            </Field>
          </div>
          {error && (
            <p id={nameErrorId} className="text-sm font-semibold text-starText">
              {error}
            </p>
          )}
        </>
      );
    case 'email':
      return (
        <Field label={t('roster.email')} name="email" error={errors}>
          <EmailInput
            autoComplete="off"
            value={draft.email}
            onChange={(value) => onDraft('email', value)}
          />
        </Field>
      );
    case 'phone':
      return (
        <Field label={t('roster.phone')} name="phone" error={errors}>
          <PhoneInput
            autoComplete="off"
            value={draft.phone}
            onChange={(value) => onDraft('phone', value)}
          />
        </Field>
      );
    case 'zipcode':
      return (
        <Field label={t('roster.zip')} name="zipcode" error={errors}>
          <ZipInput
            autoComplete="off"
            value={draft.zipcode}
            onChange={(value) => onDraft('zipcode', value)}
          />
        </Field>
      );
    case 'experience':
      return (
        <Field label={t('roster.years')} name="experience" error={errors}>
          {(control) => (
            <select
              {...control}
              value={draft.experience}
              onChange={(event) => onDraft('experience', event.target.value)}
              className={selectClass}
            >
              <option value="">{t('roster.yearsPlaceholder')}</option>
              {race.experience_labels.map((label, index) => (
                <option key={index} value={index}>
                  {label}
                </option>
              ))}
            </select>
          )}
        </Field>
      );
    case 'instagram':
      return (
        <Field label={t('roster.instagramLine')} name="instagram" error={errors}>
          <Input
            autoComplete="off"
            autoCapitalize="none"
            placeholder={t('roster.instagramPlaceholder')}
            value={draft.instagram}
            onChange={(event) => onDraft('instagram', event.target.value)}
          />
        </Field>
      );
  }
}
