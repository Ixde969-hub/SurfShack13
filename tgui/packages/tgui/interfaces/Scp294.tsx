import { useState } from 'react';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Beaker, BeakerDisplay } from './common/BeakerDisplay';

type Data = {
  beaker: Beaker | null;
  amount: number;
  status: string | null;
  status_error: boolean;
};

export const Scp294 = (props) => {
  const { act, data } = useBackend<Data>();
  const { beaker, amount, status, status_error } = data;
  const [liquid, setLiquid] = useState('');

  const submit = (value: string) => {
    if (!value.trim()) {
      return;
    }
    act('dispense', { name: value });
    setLiquid('');
  };

  return (
    <Window width={390} height={340} theme="ntos">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Touchpad">
              <Stack>
                <Stack.Item grow>
                  <Input
                    fluid
                    autoFocus
                    disabled={!beaker}
                    placeholder="Enter the name of any liquid"
                    value={liquid}
                    onChange={setLiquid}
                    onEnter={submit}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="mug-hot"
                    disabled={!beaker || !liquid.trim()}
                    onClick={() => submit(liquid)}
                  >
                    Pour {amount}u
                  </Button>
                </Stack.Item>
              </Stack>
              {!!status && (
                <NoticeBox mt={1} danger={!!status_error} info={!status_error}>
                  {status}
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section
              fill
              title="Cup"
              buttons={
                beaker ? (
                  <Button icon="eject" onClick={() => act('eject')}>
                    Eject
                  </Button>
                ) : (
                  <Button icon="plus" onClick={() => act('makecup')}>
                    Dispense Cup
                  </Button>
                )
              }
            >
              {beaker ? (
                <BeakerDisplay beaker={beaker} />
              ) : (
                <Box color="label">No cup inserted.</Box>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
