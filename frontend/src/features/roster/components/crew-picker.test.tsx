import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { PastRacer } from '@/features/roster/api/use-past-racers';
import { CrewPicker } from '@/features/roster/components/crew-picker';
import { clearCsrfToken } from '@/lib/api-client';
import { buildPerson, buildRace, buildTeam } from '@/test/fixtures';
import { server } from '@/test/server';

const base: PastRacer = {
  first_name: '',
  last_name: '',
  email: '',
  phone: null,
  zipcode: null,
  experience: 0,
  instagram: null,
  last_team_name: 'Cart Pushers',
  last_race_name: 'CHIditarod 2025',
  last_raced_year: 2025,
};

const ada: PastRacer = {
  ...base,
  first_name: 'Ada',
  last_name: 'Lovelace',
  email: 'ada@example.com',
  phone: '312-555-0111',
  zipcode: '60614',
  experience: 0,
};
const grace: PastRacer = {
  ...base,
  first_name: 'Grace',
  last_name: 'Hopper',
  email: 'grace@example.com',
  phone: '312-555-0112',
  zipcode: '60647',
  experience: 1,
};
const edsger: PastRacer = {
  ...base,
  first_name: 'Edsger',
  last_name: 'Dijkstra',
  email: 'edsger@example.com',
  phone: null,
  zipcode: '60622',
  experience: 0,
};

const racer = (n: number): PastRacer => ({
  ...base,
  first_name: `Racer${n}`,
  last_name: `Num${n}`,
  email: `racer${n}@example.com`,
  phone: '312-555-0100',
  zipcode: '60601',
});

let posts: unknown[];

beforeEach(() => {
  posts = [];
  server.use(http.get('/api/v1/csrf', () => HttpResponse.json({ token: 't' })));
});
afterEach(() => {
  clearCsrfToken();
  vi.unstubAllGlobals();
});

function serveSave(respond?: (body: { person: PastRacer }) => Response) {
  server.use(
    http.post('/api/v1/teams/9/people', async ({ request }) => {
      const body = (await request.json()) as { person: PastRacer };
      posts.push(body);
      if (respond) return respond(body);
      return HttpResponse.json({
        person: buildPerson({ id: posts.length, ...body.person }),
        checklist: buildTeam().checklist,
      });
    }),
  );
}

const errorResponse = (status: number, error: string, errors = {}) =>
  HttpResponse.json({ error, errors }, { status });

function setup(props: Partial<Parameters<typeof CrewPicker>[0]> = {}) {
  const onAdded = vi.fn();
  const onForbidden = vi.fn();
  const onClose = vi.fn();
  const user = userEvent.setup();
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  const { unmount } = render(
    <QueryClientProvider client={queryClient}>
      <button type="button">Page behind</button>
      <CrewPicker
        team={buildTeam({ race: buildRace() })}
        racers={[ada, grace, edsger]}
        openSpots={3}
        onAdded={onAdded}
        onForbidden={onForbidden}
        onClose={onClose}
        {...props}
      />
    </QueryClientProvider>,
  );
  return { user, onAdded, onForbidden, onClose, unmount };
}

const row = (name: string) => screen.getByRole('checkbox', { name: new RegExp(`^${name}`) });
const line = (label: string) => screen.getByRole('checkbox', { name: new RegExp(`^${label}: `) });

async function confirmAll(user: ReturnType<typeof userEvent.setup>) {
  for (const label of ['Name', 'Email', 'Phone', 'ZIP code', 'Years racing', 'Instagram']) {
    await user.click(line(label));
  }
}

async function reviewOne(user: ReturnType<typeof userEvent.setup>, name = 'Ada') {
  await user.click(row(name));
  await user.click(screen.getByRole('button', { name: 'Review 1 racer' }));
}

describe('pick step', () => {
  it('stops at the number of open spots and says so', async () => {
    const { user } = setup({ openSpots: 2 });
    expect(screen.getByRole('dialog', { name: 'Pick from past teams' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Review racers' })).toBeDisabled();
    expect(screen.getByText('2 spots left')).toBeInTheDocument();
    expect(row('Ada')).toHaveTextContent('2025, Cart Pushers');

    await user.click(row('Ada'));
    await user.click(row('Grace'));
    expect(row('Edsger')).toBeDisabled();
    expect(row('Ada')).toBeEnabled();
    expect(screen.getByText('All 2 spots picked')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Review 2 racers' })).toBeEnabled();

    await user.click(row('Grace'));
    expect(row('Edsger')).toBeEnabled();
    expect(screen.getByText('1 spot left')).toBeInTheDocument();
  });

  it('says the open spot is picked when there is one', async () => {
    const { user } = setup({ openSpots: 1 });
    await user.click(row('Ada'));
    expect(screen.getByText('The open spot is picked')).toBeInTheDocument();
  });

  it('shows just the team when a racer has no year', () => {
    setup({ racers: [{ ...ada, last_raced_year: null }] });
    expect(row('Ada')).toHaveTextContent(/^Ada LovelaceCart Pushers$/);
  });

  it('filters by name and says when nothing matches, with more than six racers', async () => {
    const { user } = setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3), racer(4), racer(5)] });
    const search = screen.getByRole('searchbox', { name: 'Search past racers' });
    expect(search).toHaveAttribute('placeholder', 'Search 8 past racers');

    await user.type(search, 'gra');
    expect(screen.getAllByRole('checkbox')).toHaveLength(1);
    expect(row('Grace')).toBeInTheDocument();

    await user.clear(search);
    await user.type(search, 'zzz');
    expect(screen.getByText('No past racers match.')).toBeInTheDocument();
  });

  it('clears the search on Escape before closing', async () => {
    const { user, onClose } = setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3), racer(4)] });
    const search = screen.getByRole('searchbox', { name: 'Search past racers' });
    await user.type(search, 'gra');
    await user.keyboard('{Escape}');
    expect(search).toHaveValue('');
    expect(screen.getAllByRole('checkbox')).toHaveLength(7);
    expect(onClose).not.toHaveBeenCalled();

    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('has no search box with six racers or fewer', () => {
    setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3)] });
    expect(screen.queryByRole('searchbox')).not.toBeInTheDocument();
    expect(screen.getByRole('dialog')).not.toHaveClass('h-[90dvh]');
  });

  it('holds a fixed height while the list can be searched, so it does not jump', () => {
    setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3), racer(4)] });
    expect(screen.getByRole('dialog')).toHaveClass('h-[90dvh]', 'sm:h-[min(40rem,90dvh)]');
  });

  it('focuses the search box with a fine pointer', () => {
    setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3), racer(4)] });
    expect(screen.getByRole('searchbox', { name: 'Search past racers' })).toHaveFocus();
  });

  it('focuses the title, not the search box, on a touch screen', () => {
    vi.stubGlobal('matchMedia', (query: string) => ({ matches: false, media: query }));
    setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3), racer(4)] });
    expect(screen.getByRole('heading', { name: 'Pick from past teams' })).toHaveFocus();
  });

  it('brings Tab back into the dialog when focus has fallen to the page', async () => {
    const { user } = setup();
    (document.activeElement as HTMLElement).blur();
    expect(document.body).toHaveFocus();

    await user.tab();
    expect(screen.getByRole('button', { name: 'Close' })).toHaveFocus();

    (document.activeElement as HTMLElement).blur();
    await user.tab({ shift: true });
    expect(row('Edsger')).toHaveFocus();
  });

  it('keeps Shift+Tab from the title inside the dialog', async () => {
    const { user } = setup();
    expect(screen.getByRole('heading', { name: 'Pick from past teams' })).toHaveFocus();
    await user.tab({ shift: true });
    expect(row('Edsger')).toHaveFocus();
  });

  it('stops the page behind from scrolling while open', () => {
    const { unmount } = setup();
    expect(document.documentElement.style.overflow).toBe('hidden');
    expect(document.body.style.overflow).toBe('hidden');
    unmount();
    expect(document.documentElement.style.overflow).toBe('');
    expect(document.body.style.overflow).toBe('');
  });

  it('closes on Escape and on Close', async () => {
    const { user, onClose } = setup();
    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalledTimes(1);
    await user.click(screen.getByRole('button', { name: 'Close' }));
    expect(onClose).toHaveBeenCalledTimes(2);
  });
});

describe('review step', () => {
  it('gates adding on confirming all six lines', async () => {
    const { user } = setup();
    await reviewOne(user);
    expect(screen.getByRole('heading', { name: 'Review Ada Lovelace' })).toBeInTheDocument();
    expect(screen.getByText('Last raced 2025 with Cart Pushers')).toBeInTheDocument();
    expect(screen.getByText('1 of 1')).toBeInTheDocument();

    const add = screen.getByRole('button', { name: 'Add Ada to the team' });
    expect(add).toBeDisabled();
    expect(
      screen.getByText('6 details left to confirm. Tick each line once you have checked it.'),
    ).toBeInTheDocument();

    await confirmAll(user);
    expect(add).toBeEnabled();
    expect(screen.getByText('All six details confirmed.')).toBeInTheDocument();
    expect(line('Name')).toBeChecked();
  });

  it('shows the instagram line as None', async () => {
    const { user } = setup();
    await reviewOne(user);
    expect(line('Instagram')).toHaveAccessibleName('Instagram: None');
  });

  it('notes the years it was bumped from', async () => {
    const { user } = setup();
    await reviewOne(user);
    expect(line('Years racing')).toHaveAccessibleName('Years racing: Raced once before');
    expect(screen.getByText('was "This is our first" last time')).toBeInTheDocument();
  });

  it('lets a line be changed and confirms it on Done', async () => {
    const { user } = setup();
    await reviewOne(user);
    await user.click(screen.getByRole('button', { name: 'Change email' }));
    const email = screen.getByRole('textbox', { name: 'Email' });
    await user.clear(email);
    await user.type(email, 'new@example.com');
    await user.click(screen.getByRole('button', { name: 'Done' }));

    expect(line('Email')).toBeChecked();
    expect(line('Email')).toHaveAccessibleName('Email: new@example.com');
    expect(line('Email')).toHaveFocus();
  });

  it('puts a changed line back on Escape and stays open', async () => {
    const { user, onClose } = setup();
    await reviewOne(user);
    await user.click(line('Email'));
    await user.click(screen.getByRole('button', { name: 'Change email' }));
    const email = screen.getByRole('textbox', { name: 'Email' });
    await user.clear(email);
    await user.type(email, 'new@example.com');
    await user.keyboard('{Escape}');

    expect(onClose).not.toHaveBeenCalled();
    expect(line('Email')).toHaveAccessibleName('Email: ada@example.com');
    expect(line('Email')).toBeChecked();
    expect(line('Email')).toHaveFocus();
  });

  it('closes on Escape from a missing detail, which has nothing to go back to', async () => {
    const { user, onClose } = setup();
    await reviewOne(user, 'Edsger');
    await user.click(screen.getByRole('textbox', { name: 'Phone' }));
    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('names ZIP code and Instagram as written on their Change buttons', async () => {
    const { user } = setup();
    await reviewOne(user);
    expect(screen.getByRole('button', { name: 'Change ZIP code' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Change Instagram' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Change years racing' })).toBeInTheDocument();
  });

  it('edits the name with two inputs', async () => {
    const { user } = setup();
    await reviewOne(user);
    await user.click(screen.getByRole('button', { name: 'Change name' }));
    await user.clear(screen.getByRole('textbox', { name: 'First name' }));
    await user.type(screen.getByRole('textbox', { name: 'First name' }), 'Augusta');
    await user.click(screen.getByRole('button', { name: 'Done' }));
    expect(line('Name')).toHaveAccessibleName('Name: Augusta Lovelace');
    expect(screen.getByRole('heading', { name: 'Review Augusta Lovelace' })).toBeInTheDocument();
  });

  it('opens a missing detail in its input and will not confirm it empty', async () => {
    const { user } = setup();
    await reviewOne(user, 'Edsger');
    const phone = screen.getByRole('textbox', { name: 'Phone' });
    expect(screen.getByText('Phone is missing. Add it to continue.')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Done' }));
    expect(screen.getByText('Phone is missing. Add it to continue.')).toBeInTheDocument();
    // Focus goes to the empty input, whose description is the error.
    expect(phone).toHaveFocus();
    expect(phone).toHaveAccessibleDescription('Phone is missing. Add it to continue.');

    await user.type(phone, '3125550113');
    await user.click(screen.getByRole('button', { name: 'Done' }));
    expect(line('Phone')).toBeChecked();
    expect(line('Phone')).toHaveAccessibleName('Phone: (312) 555-0113');
  });

  it('reads out the missing message each time Enter cannot finish a blank line', async () => {
    const { user } = setup();
    await reviewOne(user, 'Edsger');
    const phone = screen.getByRole('textbox', { name: 'Phone' });
    const notice = within(screen.getByRole('dialog')).getAllByRole('status')[0];
    expect(notice).toHaveTextContent('');

    await user.click(phone);
    await user.keyboard('{Enter}');
    expect(notice.textContent).toBe('Phone is missing. Add it to continue.');
    await user.keyboard('{Enter}');
    expect(notice.textContent).toBe('Phone is missing. Add it to continue.\u00a0');
    expect(phone).toHaveFocus();
  });

  it('keeps the years line open until something is chosen', async () => {
    const { user } = setup({ racers: [{ ...ada, experience: null }] });
    await reviewOne(user);
    const select = screen.getByRole('combobox', { name: 'Years racing' });
    expect(select).toHaveDisplayValue('Select one');

    await user.click(screen.getByRole('button', { name: 'Done' }));
    expect(screen.getByRole('combobox', { name: 'Years racing' })).toBeInTheDocument();
    expect(screen.getByText('Years racing is missing. Add it to continue.')).toBeInTheDocument();

    await user.selectOptions(select, 'Twice');
    await user.click(screen.getByRole('button', { name: 'Done' }));
    expect(line('Years racing')).toHaveAccessibleName('Years racing: Twice');
  });

  it('blocks adding again as soon as a confirmed line is reopened', async () => {
    const { user } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Change email' }));

    expect(screen.getByRole('button', { name: 'Add Ada to the team' })).toBeDisabled();
    expect(
      screen.getByText('1 detail left to confirm. Tick each line once you have checked it.'),
    ).toBeInTheDocument();
  });

  it('keeps a confirmed years line open and unsaved when it is changed to nothing', async () => {
    serveSave();
    const { user } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Change years racing' }));
    await user.selectOptions(screen.getByRole('combobox', { name: 'Years racing' }), 'Select one');
    await user.click(screen.getByRole('button', { name: 'Done' }));

    expect(screen.getByRole('combobox', { name: 'Years racing' })).toBeInTheDocument();
    expect(screen.getByText('Years racing is missing. Add it to continue.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Add Ada to the team' })).toBeDisabled();
    expect(posts).toHaveLength(0);
  });

  it('does not save when Enter is pressed in an open editor', async () => {
    serveSave();
    const { user } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Change email' }));
    const email = screen.getByRole('textbox', { name: 'Email' });
    await user.clear(email);
    await user.type(email, '{Enter}');

    expect(screen.getByRole('textbox', { name: 'Email' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Add Ada to the team' })).toBeDisabled();
    expect(posts).toHaveLength(0);
  });

  it('wraps long values', async () => {
    const { user } = setup({
      racers: [{ ...ada, email: 'a.very.long.email.address.for.ada@example-with-a-long-domain.org' }],
    });
    await reviewOne(user);
    const value = screen.getByText('a.very.long.email.address.for.ada@example-with-a-long-domain.org');
    // `break-words` does not shrink a grid track, so the column must be minmax(0,1fr).
    expect(value).toHaveClass('[overflow-wrap:anywhere]');
    expect(value.parentElement).toHaveClass('grid-cols-[minmax(0,1fr)]');
  });

  it('keeps its natural height', async () => {
    const { user } = setup({ racers: [ada, grace, edsger, racer(1), racer(2), racer(3), racer(4)] });
    await reviewOne(user);
    expect(screen.getByRole('dialog')).not.toHaveClass('h-[90dvh]');
  });

  it('skips without saving and goes back with the remaining ticks', async () => {
    serveSave();
    const { user } = setup();
    await user.click(row('Ada'));
    await user.click(row('Grace'));
    await user.click(screen.getByRole('button', { name: 'Review 2 racers' }));

    await user.click(screen.getByRole('button', { name: 'Skip Ada' }));
    expect(screen.getByRole('heading', { name: 'Review Grace Hopper' })).toBeInTheDocument();
    expect(screen.getByText('2 of 2')).toBeInTheDocument();
    expect(posts).toHaveLength(0);

    await user.click(screen.getByRole('button', { name: 'Back to list' }));
    expect(row('Grace')).toBeChecked();
    expect(row('Ada')).not.toBeChecked();
  });

  it('has no way back to a list in review-only mode', () => {
    setup({ reviewOnly: ada });
    expect(screen.getByRole('heading', { name: 'Review Ada Lovelace' })).toBeInTheDocument();
    expect(screen.getByText('1 of 1')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Back to list' })).not.toBeInTheDocument();
  });
});

describe('saving', () => {
  it('posts the confirmed details, reports the person and moves to the next racer', async () => {
    serveSave();
    const { user, onAdded, onClose } = setup();
    await user.click(row('Ada'));
    await user.click(row('Grace'));
    await user.click(screen.getByRole('button', { name: 'Review 2 racers' }));
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Add Ada to the team' }));

    expect(await screen.findByRole('heading', { name: 'Review Grace Hopper' })).toBeInTheDocument();
    expect(screen.getByText('2 of 2')).toBeInTheDocument();
    expect(posts).toEqual([
      {
        person: {
          first_name: 'Ada',
          last_name: 'Lovelace',
          email: 'ada@example.com',
          phone: '312-555-0111',
          zipcode: '60614',
          experience: 1,
          instagram: '',
        },
      },
    ]);
    expect(onAdded).toHaveBeenCalledWith(expect.objectContaining({ email: 'ada@example.com' }), ada);
    expect(onClose).not.toHaveBeenCalled();
    expect(screen.getByRole('button', { name: 'Add Grace to the team' })).toBeDisabled();

    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Add Grace to the team' }));
    await waitFor(() => expect(onClose).toHaveBeenCalledTimes(1));
    expect(posts).toHaveLength(2);
  });

  it('sends one request for a double tap', async () => {
    serveSave();
    const { user, onAdded } = setup({ reviewOnly: ada });
    await confirmAll(user);
    const add = screen.getByRole('button', { name: 'Add Ada to the team' });
    fireEvent.click(add);
    fireEvent.click(add);
    await waitFor(() => expect(onAdded).toHaveBeenCalled());
    expect(posts).toHaveLength(1);
  });

  it('will not close while a save is in flight', async () => {
    let finish: () => void = () => {};
    const held = new Promise<void>((resolve) => {
      finish = resolve;
    });
    server.use(
      http.post('/api/v1/teams/9/people', async ({ request }) => {
        const body = (await request.json()) as { person: PastRacer };
        posts.push(body);
        await held;
        return HttpResponse.json({
          person: buildPerson({ id: 1, ...body.person }),
          checklist: buildTeam().checklist,
        });
      }),
    );
    const { user, onAdded, onClose } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Add Ada to the team' }));
    await waitFor(() => expect(posts).toHaveLength(1));

    expect(screen.getByRole('button', { name: 'Close' })).toBeDisabled();
    await user.keyboard('{Escape}');
    expect(onClose).not.toHaveBeenCalled();

    finish();
    await waitFor(() => expect(onAdded).toHaveBeenCalledTimes(1));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('reopens the line a field error names, unconfirmed, with its message', async () => {
    serveSave(() => errorResponse(422, 'Invalid', { email: ['has already been taken'] }));
    const { user, onClose } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Add Ada to the team' }));

    expect(await screen.findByRole('textbox', { name: 'Email' })).toBeInTheDocument();
    expect(screen.getByText('has already been taken')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Add Ada to the team' })).toBeDisabled();
    expect(line('Phone')).toBeChecked();
    expect(onClose).not.toHaveBeenCalled();
  });

  it('shows other errors, such as a full team, and stays open', async () => {
    serveSave(() => errorResponse(422, 'Invalid', { maximum: ['Team is full'] }));
    const { user, onClose } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Add Ada to the team' }));

    const alert = await screen.findByRole('alert');
    expect(alert).toHaveTextContent('Team is full');
    expect(alert).toHaveFocus();
    expect(screen.getByRole('dialog')).toContainElement(document.activeElement as HTMLElement);
    expect(screen.getByRole('button', { name: 'Add Ada to the team' })).toBeEnabled();
    expect(onClose).not.toHaveBeenCalled();
  });

  it('hands a 403 to the page and closes', async () => {
    serveSave(() => errorResponse(403, 'Registration is closed'));
    const { user, onForbidden, onClose } = setup({ reviewOnly: ada });
    await confirmAll(user);
    await user.click(screen.getByRole('button', { name: 'Add Ada to the team' }));

    await waitFor(() => expect(onForbidden).toHaveBeenCalledTimes(1));
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
