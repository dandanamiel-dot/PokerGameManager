// Security rules tests for firestore.rules, run against the Firestore emulator.
//   cd firestore-tests && npm install && npm test
import { test, before, beforeEach, after, describe } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs,
  arrayUnion, arrayRemove, deleteField, serverTimestamp, Timestamp,
} from 'firebase/firestore';

const HOST = 'host-uid';
const COADMIN = 'coadmin-uid';
const VIEWER = 'viewer-uid';
const STRANGER = 'stranger-uid';
const CODE = '123456';
const GROUP = 'ABC234';

let env;

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

/** A room as the v1.1 app writes it. */
function newRoom(overrides = {}) {
  return {
    roomCode: CODE,
    hostId: HOST,
    status: 'active',
    createdAt: Timestamp.fromDate(new Date('2026-09-29T20:00:00Z')),
    totalPot: 100,
    players: [{ id: 'p1', name: 'Dan', avatar: 'person', totalBuyIn: 100, buyInCount: 1, profitLoss: -100 }],
    buyInTimeline: [],
    settlement: [],
    schemaVersion: 2,
    adminIds: [HOST],
    adminNames: { [HOST]: 'Dan' },
    groupId: GROUP,
    ...overrides,
  };
}

/** A room as v1.0 wrote it: no adminIds or schemaVersion. */
function legacyRoom() {
  const room = newRoom();
  delete room.adminIds;
  delete room.adminNames;
  delete room.schemaVersion;
  delete room.groupId;
  return room;
}

function group(overrides = {}) {
  return {
    groupId: GROUP,
    name: 'Friday Poker',
    currency: 'ILS',
    currencySymbol: '₪',
    createdBy: HOST,
    createdAt: Timestamp.fromMillis(Date.parse('2026-01-01T10:00:00.123Z')),
    memberIds: [HOST, VIEWER],
    memberNames: { [HOST]: 'Dan', [VIEWER]: 'Avi' },
    ...overrides,
  };
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-poker-rules',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  await env.cleanup();
});

describe('rooms: creating', () => {
  test('host creates a room with only themselves as admin', async () => {
    await assertSucceeds(setDoc(doc(db(HOST), `rooms/${CODE}`), newRoom()));
  });

  test('v1.0 host can still create a room without adminIds', async () => {
    await assertSucceeds(setDoc(doc(db(HOST), `rooms/${CODE}`), legacyRoom()));
  });

  test('cannot create a room in someone else\'s name', async () => {
    await assertFails(setDoc(doc(db(STRANGER), `rooms/${CODE}`), newRoom()));
  });

  test('cannot create a room that already lists other admins', async () => {
    await assertFails(setDoc(doc(db(HOST), `rooms/${CODE}`), newRoom({ adminIds: [HOST, STRANGER] })));
  });

  test('room code in the document must match its id', async () => {
    await assertFails(setDoc(doc(db(HOST), 'rooms/999999'), newRoom()));
  });

  test('signed-out users cannot create rooms', async () => {
    await assertFails(setDoc(doc(db(null), `rooms/${CODE}`), newRoom()));
  });
});

describe('rooms: watching', () => {
  beforeEach(async () => {
    await seed(`rooms/${CODE}`, newRoom());
    await seed(`groups/${GROUP}`, group());
  });

  test('anyone signed in with the code can watch', async () => {
    await assertSucceeds(getDoc(doc(db(STRANGER), `rooms/${CODE}`)));
  });

  test('signed-out users cannot watch', async () => {
    await assertFails(getDoc(doc(db(null), `rooms/${CODE}`)));
  });

  test('nobody can list every room', async () => {
    await assertFails(getDocs(collection(db(STRANGER), 'rooms')));
  });

  test('group members can list their group\'s live games', async () => {
    await assertSucceeds(getDocs(query(collection(db(VIEWER), 'rooms'), where('groupId', '==', GROUP), where('status', '==', 'active'))));
  });

  test('non-members cannot list a group\'s games', async () => {
    await assertFails(getDocs(query(collection(db(STRANGER), 'rooms'), where('groupId', '==', GROUP))));
  });
});

describe('rooms: running the game', () => {
  beforeEach(async () => {
    await seed(`rooms/${CODE}`, newRoom({ adminIds: [HOST, COADMIN] }));
  });

  test('host records a buy-in', async () => {
    await assertSucceeds(updateDoc(doc(db(HOST), `rooms/${CODE}`), { totalPot: 200 }));
  });

  test('co-admin records a buy-in when the host is gone', async () => {
    await assertSucceeds(updateDoc(doc(db(COADMIN), `rooms/${CODE}`), { totalPot: 200, updatedBy: COADMIN }));
  });

  test('co-admin writes the whole room (as the app\'s transaction does)', async () => {
    const room = newRoom({ adminIds: [HOST, COADMIN], status: 'completed', updatedBy: COADMIN });
    await assertSucceeds(setDoc(doc(db(COADMIN), `rooms/${CODE}`), room));
  });

  test('a viewer cannot change the game', async () => {
    await assertFails(updateDoc(doc(db(VIEWER), `rooms/${CODE}`), { totalPot: 0 }));
  });

  test('a viewer cannot make themselves admin', async () => {
    await assertFails(updateDoc(doc(db(VIEWER), `rooms/${CODE}`), { adminIds: arrayUnion(VIEWER) }));
  });

  test('nobody can take over as host', async () => {
    await assertFails(updateDoc(doc(db(COADMIN), `rooms/${CODE}`), { hostId: COADMIN }));
  });

  test('co-admin can add another admin', async () => {
    await assertSucceeds(updateDoc(doc(db(COADMIN), `rooms/${CODE}`), { adminIds: [HOST, COADMIN, VIEWER] }));
  });

  test('co-admin cannot remove other admins', async () => {
    await assertFails(updateDoc(doc(db(COADMIN), `rooms/${CODE}`), { adminIds: [HOST] }));
  });

  test('host can remove a co-admin', async () => {
    await assertSucceeds(updateDoc(doc(db(HOST), `rooms/${CODE}`), { adminIds: arrayRemove(COADMIN) }));
  });

  test('removed co-admin loses access', async () => {
    await updateDoc(doc(db(HOST), `rooms/${CODE}`), { adminIds: [HOST] });
    await assertFails(updateDoc(doc(db(COADMIN), `rooms/${CODE}`), { totalPot: 0 }));
  });

  test('only the host can delete the room', async () => {
    await assertFails(deleteDoc(doc(db(COADMIN), `rooms/${CODE}`)));
    await assertFails(deleteDoc(doc(db(STRANGER), `rooms/${CODE}`)));
    await assertSucceeds(deleteDoc(doc(db(HOST), `rooms/${CODE}`)));
  });
});

describe('rooms: v1.0 compatibility', () => {
  beforeEach(async () => {
    await seed(`rooms/${CODE}`, legacyRoom());
  });

  test('v1.0 host keeps syncing with merge writes', async () => {
    await assertSucceeds(setDoc(doc(db(HOST), `rooms/${CODE}`), { totalPot: 300 }, { merge: true }));
  });

  test('v1.0 host posts the settlement', async () => {
    await assertSucceeds(updateDoc(doc(db(HOST), `rooms/${CODE}`), { status: 'completed', settlement: [] }));
  });

  test('others still cannot write a v1.0 room', async () => {
    await assertFails(setDoc(doc(db(STRANGER), `rooms/${CODE}`), { totalPot: 0 }, { merge: true }));
  });
});

describe('rooms: presence', () => {
  beforeEach(async () => {
    await seed(`rooms/${CODE}`, newRoom());
  });

  const heartbeat = (uid, name = 'Avi') => ({ uid, name, lastSeen: serverTimestamp() });

  test('a viewer announces themselves', async () => {
    await assertSucceeds(setDoc(doc(db(VIEWER), `rooms/${CODE}/viewers/${VIEWER}`), heartbeat(VIEWER)));
  });

  test('everyone in the room sees who is watching', async () => {
    await seed(`rooms/${CODE}/viewers/${VIEWER}`, { uid: VIEWER, name: 'Avi' });
    await assertSucceeds(getDocs(collection(db(HOST), `rooms/${CODE}/viewers`)));
  });

  test('cannot write someone else\'s presence', async () => {
    await assertFails(setDoc(doc(db(STRANGER), `rooms/${CODE}/viewers/${VIEWER}`), heartbeat(VIEWER)));
    await assertFails(setDoc(doc(db(STRANGER), `rooms/${CODE}/viewers/${STRANGER}`), heartbeat(VIEWER)));
  });

  test('names are capped at 40 characters', async () => {
    await assertFails(setDoc(doc(db(VIEWER), `rooms/${CODE}/viewers/${VIEWER}`), heartbeat(VIEWER, 'x'.repeat(41))));
  });

  test('leaving removes only your own entry', async () => {
    await seed(`rooms/${CODE}/viewers/${VIEWER}`, { uid: VIEWER, name: 'Avi' });
    await assertFails(deleteDoc(doc(db(STRANGER), `rooms/${CODE}/viewers/${VIEWER}`)));
    await assertSucceeds(deleteDoc(doc(db(VIEWER), `rooms/${CODE}/viewers/${VIEWER}`)));
  });
});

describe('groups', () => {
  beforeEach(async () => {
    await seed(`groups/${GROUP}`, group());
  });

  test('creating a group with only yourself as member', async () => {
    await assertSucceeds(setDoc(doc(db(STRANGER), 'groups/NEW234'),
      group({ groupId: 'NEW234', createdBy: STRANGER, memberIds: [STRANGER], memberNames: { [STRANGER]: 'Noa' } })));
  });

  test('cannot create a group for someone else', async () => {
    await assertFails(setDoc(doc(db(STRANGER), 'groups/NEW234'), group({ groupId: 'NEW234' })));
  });

  test('anyone with the code can look the group up to join', async () => {
    await assertSucceeds(getDoc(doc(db(STRANGER), `groups/${GROUP}`)));
  });

  test('members list their groups', async () => {
    await assertSucceeds(getDocs(query(collection(db(VIEWER), 'groups'), where('memberIds', 'array-contains', VIEWER))));
  });

  test('cannot list groups you are not in', async () => {
    await assertFails(getDocs(collection(db(STRANGER), 'groups')));
  });

  test('joining adds yourself (v1.1 field update)', async () => {
    await assertSucceeds(updateDoc(doc(db(STRANGER), `groups/${GROUP}`), {
      memberIds: arrayUnion(STRANGER),
      [`memberNames.${STRANGER}`]: 'Noa',
    }));
  });

  test('joining with a v1.0 whole-document merge still works', async () => {
    const g = group();
    g.memberIds = [...g.memberIds, STRANGER];
    g.memberNames = { ...g.memberNames, [STRANGER]: 'Noa' };
    // Round-tripping through Swift's Date can move createdAt by a microsecond
    g.createdAt = Timestamp.fromMillis(g.createdAt.toMillis() - 0.001);
    await assertSucceeds(setDoc(doc(db(STRANGER), `groups/${GROUP}`), g, { merge: true }));
  });

  test('joining cannot add other people', async () => {
    await assertFails(updateDoc(doc(db(STRANGER), `groups/${GROUP}`), { memberIds: arrayUnion(STRANGER, 'friend-uid') }));
  });

  test('joining cannot rename the group or take it over', async () => {
    await assertFails(updateDoc(doc(db(STRANGER), `groups/${GROUP}`), { memberIds: arrayUnion(STRANGER), name: 'Mine now' }));
    await assertFails(updateDoc(doc(db(STRANGER), `groups/${GROUP}`), { memberIds: arrayUnion(STRANGER), createdBy: STRANGER }));
  });

  test('joining cannot change other members\' names', async () => {
    await assertFails(updateDoc(doc(db(STRANGER), `groups/${GROUP}`), {
      memberIds: arrayUnion(STRANGER),
      [`memberNames.${HOST}`]: 'Loser',
    }));
  });

  test('a member cannot remove someone else', async () => {
    await assertFails(updateDoc(doc(db(VIEWER), `groups/${GROUP}`), { memberIds: arrayRemove(HOST) }));
  });

  test('a member can leave', async () => {
    await assertSucceeds(updateDoc(doc(db(VIEWER), `groups/${GROUP}`), {
      memberIds: arrayRemove(VIEWER),
      [`memberNames.${VIEWER}`]: deleteField(),
    }));
  });

  test('the creator can remove a member', async () => {
    await assertSucceeds(updateDoc(doc(db(HOST), `groups/${GROUP}`), {
      memberIds: arrayRemove(VIEWER),
      [`memberNames.${VIEWER}`]: deleteField(),
    }));
  });

  test('the creator cannot hand the group\'s ownership field to someone else', async () => {
    await assertFails(updateDoc(doc(db(HOST), `groups/${GROUP}`), { createdBy: VIEWER }));
  });

  test('only the creator can delete the group', async () => {
    await assertFails(deleteDoc(doc(db(VIEWER), `groups/${GROUP}`)));
    await assertSucceeds(deleteDoc(doc(db(HOST), `groups/${GROUP}`)));
  });
});
