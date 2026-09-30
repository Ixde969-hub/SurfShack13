import { type ReactNode, useState } from 'react';
import { Box, Button, Input, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Beaker } from './common/BeakerDisplay';

type Data = {
  beaker: Beaker | null;
  amount: number;
  cup_color: string | null;
  status: string | null;
  status_error: boolean;
};

const KEY_ROWS = ['1234567890', 'QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

const MAX_LENGTH = 40;

const Screen = (props: { children: ReactNode }) => (
  <Box
    style={{
      background: '#0b1a10',
      border: '2px inset #2b3a2f',
      borderRadius: '4px',
      boxShadow: 'inset 0 0 12px rgba(0, 0, 0, 0.8)',
      fontFamily: 'monospace',
      padding: '6px 8px',
    }}
  >
    {props.children}
  </Box>
);

const Cup = (props: { beaker: Beaker | null; color: string | null }) => {
  const { beaker, color } = props;
  const fill = beaker?.maxVolume
    ? Math.min(100, (beaker.currentVolume / beaker.maxVolume) * 100)
    : 0;
  return (
    <Box
      style={{
        alignItems: 'flex-end',
        display: 'flex',
        height: '100%',
        justifyContent: 'center',
      }}
    >
      {beaker ? (
        <Box
          style={{
            background: '#e8e4d8',
            clipPath: 'polygon(0 0, 100% 0, 88% 100%, 12% 100%)',
            height: '86px',
            overflow: 'hidden',
            position: 'relative',
            width: '72px',
          }}
        >
          <Box
            style={{
              background: color || '#ffffff',
              bottom: 0,
              height: `${fill}%`,
              left: 0,
              position: 'absolute',
              transition: 'height 0.6s',
              width: '100%',
            }}
          />
        </Box>
      ) : (
        <Box
          style={{
            border: '2px dashed #4a4a4a',
            borderRadius: '2px 2px 10px 10px',
            height: '86px',
            width: '72px',
          }}
        />
      )}
    </Box>
  );
};

export const Scp294 = (props) => {
  const { act, data } = useBackend<Data>();
  const { beaker, amount, cup_color, status, status_error } = data;
  const [liquid, setLiquid] = useState('');

  const append = (char: string) =>
    setLiquid((old) => (old.length < MAX_LENGTH ? old + char : old));

  const submit = (value: string) => {
    if (!beaker || !value.trim()) {
      return;
    }
    act('dispense', { name: value });
    setLiquid('');
  };

  const contents = beaker?.contents ?? [];

  return (
    <Window width={400} height={520}>
      <Window.Content>
        <Box
          style={{
            background: 'linear-gradient(#3b3630, #24211e)',
            border: '3px solid #57504a',
            borderRadius: '8px',
            height: '100%',
            padding: '10px',
          }}
        >
          <Stack vertical fill>
            <Stack.Item>
              <Box
                style={{
                  color: '#d9c7a3',
                  fontFamily: 'monospace',
                  fontSize: '14px',
                  letterSpacing: '3px',
                  paddingBottom: '6px',
                  textAlign: 'center',
                }}
              >
                SCP-294
              </Box>
              <Screen>
                <Box
                  style={{
                    color: status_error ? '#ff5a4d' : '#6dff8f',
                    minHeight: '18px',
                  }}
                >
                  {status || 'ENTER LIQUID'}
                </Box>
                <Input
                  fluid
                  autoFocus
                  disabled={!beaker}
                  maxLength={MAX_LENGTH}
                  placeholder={beaker ? 'type a liquid...' : 'INSERT CUP'}
                  value={liquid}
                  onChange={(e, value) => setLiquid(value)}
                  onEnter={(e, value) => submit(value)}
                />
              </Screen>
            </Stack.Item>
            <Stack.Item>
              <Box style={{ paddingTop: '4px', textAlign: 'center' }}>
                {KEY_ROWS.map((row) => (
                  <Box key={row} style={{ paddingBottom: '2px' }}>
                    {row.split('').map((char) => (
                      <Button
                        key={char}
                        disabled={!beaker}
                        minWidth="26px"
                        textAlign="center"
                        onClick={() => append(char)}
                      >
                        {char}
                      </Button>
                    ))}
                  </Box>
                ))}
                <Box>
                  <Button
                    disabled={!beaker}
                    icon="backspace"
                    onClick={() => setLiquid((old) => old.slice(0, -1))}
                  />
                  <Button
                    disabled={!beaker}
                    minWidth="120px"
                    textAlign="center"
                    onClick={() => append(' ')}
                  >
                    SPACE
                  </Button>
                  <Button
                    disabled={!beaker}
                    color="bad"
                    icon="trash"
                    onClick={() => setLiquid('')}
                  />
                  <Button
                    color="good"
                    disabled={!beaker || !liquid.trim()}
                    icon="mug-hot"
                    onClick={() => submit(liquid)}
                  >
                    POUR {amount}u
                  </Button>
                </Box>
              </Box>
            </Stack.Item>
            <Stack.Item grow>
              <Box
                style={{
                  background: '#111',
                  border: '2px inset #2a2a2a',
                  borderRadius: '4px',
                  height: '100%',
                  padding: '8px',
                }}
              >
                <Stack fill>
                  <Stack.Item basis="40%">
                    <Cup beaker={beaker} color={cup_color} />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Box
                      style={{
                        color: '#d9c7a3',
                        fontFamily: 'monospace',
                        fontSize: '12px',
                      }}
                    >
                      {beaker ? (
                        <>
                          <Box bold>
                            {beaker.currentVolume}/{beaker.maxVolume}u
                          </Box>
                          {contents.length ? (
                            contents.map((reagent) => (
                              <Box key={reagent.name}>
                                {reagent.volume}u {reagent.name}
                              </Box>
                            ))
                          ) : (
                            <Box color="label">Cup is empty.</Box>
                          )}
                        </>
                      ) : (
                        <Box color="label">No cup in the tray.</Box>
                      )}
                    </Box>
                    <Box mt={1}>
                      {beaker ? (
                        <Button icon="eject" onClick={() => act('eject')}>
                          Take cup
                        </Button>
                      ) : (
                        <Button icon="plus" onClick={() => act('makecup')}>
                          Dispense cup
                        </Button>
                      )}
                    </Box>
                  </Stack.Item>
                </Stack>
              </Box>
            </Stack.Item>
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};
