// One monotonic segment at a time. Persist accumulated milliseconds, never a wall clock.
window.TaskClock = function(record, now = () => performance.now()) {
  let since = null;
  return {
    checkpoint() {
      if (since !== null) { const next = now(); record.durationMs += Math.max(0, next - since); since = next; }
    },
    resume() { if (since === null && !record.paused && record.status === 'pending') since = now(); },
    stop(interrupted = false) { this.checkpoint(); since = null; if (interrupted && record.started && record.status === 'pending') record.interrupted = true; },
    get running() { return since !== null; },
  };
};
