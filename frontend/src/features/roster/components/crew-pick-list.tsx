import { useEffect, useMemo, useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/field';
import type { PastRacer } from '@/features/roster/api/use-past-racers';
import { TickIcon } from '@/features/roster/components/tick-icon';
import { fullName } from '@/features/roster/utils';
import { t } from '@/locales/en';

/** More racers than this and the list gets a search box. */
export const SEARCH_THRESHOLD = 6;

interface CrewPickListProps {
  titleId: string;
  racers: PastRacer[];
  /** Emails of the ticked racers, in tick order. */
  picked: string[];
  openSpots: number;
  onToggle: (email: string) => void;
  onReview: () => void;
  onClose: () => void;
}

/** A mouse or trackpad. Without `matchMedia` (jsdom) assume one. */
function hasFinePointer(): boolean {
  if (typeof window.matchMedia !== 'function') return true;
  return window.matchMedia('(hover: hover) and (pointer: fine)').matches;
}

/** "2025, Cart Pushers", the team alone, or nothing. */
function lastRaced(racer: PastRacer): string | null {
  if (racer.last_raced_year && racer.last_team_name) {
    return t('roster.lastRacedShort', {
      year: racer.last_raced_year,
      team: racer.last_team_name,
    });
  }
  return racer.last_team_name;
}

/** Step 1: tick up to `openSpots` past racers, then review them. */
export function CrewPickList({
  titleId,
  racers,
  picked,
  openSpots,
  onToggle,
  onReview,
  onClose,
}: CrewPickListProps) {
  const [query, setQuery] = useState('');
  const searchRef = useRef<HTMLInputElement>(null);
  const titleRef = useRef<HTMLHeadingElement>(null);
  const searchable = racers.length > SEARCH_THRESHOLD;

  // On a touch screen, focusing the search box opens the keyboard over the
  // sheet and hides the list, so focus the title there instead.
  useEffect(() => {
    const search = hasFinePointer() ? searchRef.current : null;
    (search ?? titleRef.current)?.focus();
  }, []);

  const matches = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return racers;
    return racers.filter((racer) =>
      `${fullName(racer)} ${racer.email}`.toLowerCase().includes(needle),
    );
  }, [racers, query]);

  const count = picked.length;
  const atCap = count >= openSpots;
  const remaining = openSpots - count;

  return (
    <>
      <div className="flex items-start justify-between gap-3 px-4 pb-2.5 pt-3.5">
        <h2
          id={titleId}
          ref={titleRef}
          tabIndex={-1}
          className="font-display text-[22px] font-semibold leading-tight focus:outline-none"
        >
          {t('roster.pickTitle')}
        </h2>
        <Button variant="ghost" className="-mt-2 shrink-0" onClick={onClose}>
          {t('roster.close')}
        </Button>
      </div>
      {searchable && (
        <div className="px-4 pb-2.5">
          <Input
            ref={searchRef}
            type="search"
            aria-label={t('roster.searchPastRacers')}
            placeholder={t('roster.searchPlaceholder', { count: racers.length })}
            autoComplete="off"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={(event) => {
              // Escape clears a search first; the next one closes the dialog.
              if (event.key === 'Escape' && query) {
                event.preventDefault();
                setQuery('');
              }
            }}
          />
        </div>
      )}
      <div className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden overscroll-contain px-4">
        <ul className="divide-y divide-flag/50">
          {matches.map((racer) => {
            const on = picked.includes(racer.email);
            const detail = lastRaced(racer);
            return (
              <li key={racer.email}>
                <button
                  type="button"
                  role="checkbox"
                  aria-checked={on}
                  disabled={!on && atCap}
                  onClick={() => onToggle(racer.email)}
                  className="flex min-h-14 w-full items-center gap-3 px-0.5 py-1.5 text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-link disabled:cursor-not-allowed disabled:opacity-40"
                >
                  <span
                    className={`grid h-6 w-6 shrink-0 place-items-center rounded-[5px] border-2 ${
                      on
                        ? 'border-navy bg-navy text-white'
                        : 'border-flag bg-white'
                    }`}
                  >
                    {on && <TickIcon />}
                  </span>
                  <span className="grid min-w-0 grid-cols-[minmax(0,1fr)]">
                    <span className="font-semibold [overflow-wrap:anywhere]">{fullName(racer)}</span>
                    {detail && (
                      <span className="text-[13px] text-navy/70 [overflow-wrap:anywhere]">{detail}</span>
                    )}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
        {matches.length === 0 && (
          <p className="py-4 text-navy/70">{t('roster.noMatches')}</p>
        )}
      </div>
      <div className="flex flex-wrap items-center gap-x-3.5 gap-y-1.5 border-t border-flag px-4 pb-4 pt-3">
        <Button
          className="flex-1 sm:flex-none"
          disabled={count === 0}
          onClick={onReview}
        >
          {count === 0
            ? t('roster.reviewNone')
            : t(count === 1 ? 'roster.reviewCount_one' : 'roster.reviewCount_other', {
                count,
              })}
        </Button>
        <span aria-live="polite" className="text-sm font-semibold text-navy/70">
          {atCap
            ? t(openSpots === 1 ? 'roster.allPicked_one' : 'roster.allPicked_other', {
                count: openSpots,
              })
            : t(remaining === 1 ? 'roster.spotsLeft_one' : 'roster.spotsLeft_other', {
                count: remaining,
              })}
        </span>
      </div>
    </>
  );
}
