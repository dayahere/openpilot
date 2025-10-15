import { run } from './index';

run().catch(err => {
  console.error('Failed to run tests:', err);
  process.exit(1);
});
