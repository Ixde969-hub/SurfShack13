import { useEffect, useRef, useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  video_id: string | null;
  video_title: string | null;
  expected_position: number;
  playback_revision: number;
  volume: number;
  distance: number;
  viewing_range: number;
  can_control: BooleanLike;
  drift_interval: number;
};

type PlayerCommand = {
  event: 'command';
  func: string;
  args: (number | boolean)[];
};

const sendPlayerCommand = (
  frame: HTMLIFrameElement | null,
  func: string,
  args: (number | boolean)[] = [],
) => {
  const command: PlayerCommand = { event: 'command', func, args };
  frame?.contentWindow?.postMessage(
    JSON.stringify(command),
    'https://www.youtube-nocookie.com',
  );
};

export const SynchronizedTelevision = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    video_id,
    video_title,
    expected_position,
    playback_revision,
    volume,
    distance,
    viewing_range,
    can_control,
    drift_interval,
  } = data;

  return (
    <Window title="Synchronized Television" width={640} height={520}>
      <Window.Content>
        <Section
          title={video_title || 'No video loaded'}
          buttons={
            <>
              {can_control && (
                <Button
                  icon="folder-open"
                  onClick={() => act('load_video')}
                >
                  Load YouTube Video
                </Button>
              )}
              {can_control && video_id && (
                <Button
                  color="bad"
                  icon="stop"
                  onClick={() => act('stop_video')}
                >
                  Stop
                </Button>
              )}
            </>
          }
        >
          {video_id ? (
            <YouTubePlayer
              key={`${video_id}:${playback_revision}`}
              videoId={video_id}
              initialPosition={expected_position}
              expectedPosition={expected_position}
              volume={volume}
              driftInterval={drift_interval}
            />
          ) : (
            <NoticeBox info>
              An administrator has not loaded a video into this television.
            </NoticeBox>
          )}
        </Section>
        <Section title="Local reception">
          <LabeledList>
            <LabeledList.Item label="Distance">
              {distance} / {viewing_range} tiles
            </LabeledList.Item>
            <LabeledList.Item label="Local volume">
              {volume}%
            </LabeledList.Item>
            <LabeledList.Item label="Synchronization">
              Server timeline, corrected every {drift_interval} seconds
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};

type YouTubePlayerProps = {
  videoId: string;
  initialPosition: number;
  expectedPosition: number;
  volume: number;
  driftInterval: number;
};

const YouTubePlayer = (props: YouTubePlayerProps) => {
  const {
    videoId,
    initialPosition,
    expectedPosition,
    volume,
    driftInterval,
  } = props;
  const playerRef = useRef<HTMLIFrameElement>(null);
  const expectedPositionRef = useRef(expectedPosition);
  const volumeRef = useRef(volume);
  const [startPosition] = useState(() => Math.max(0, Math.floor(initialPosition)));

  expectedPositionRef.current = expectedPosition;
  volumeRef.current = volume;

  const resync = () => {
    sendPlayerCommand(playerRef.current, 'seekTo', [
      expectedPositionRef.current,
      true,
    ]);
    sendPlayerCommand(playerRef.current, 'setVolume', [volumeRef.current]);
    sendPlayerCommand(playerRef.current, 'playVideo');
  };

  useEffect(() => {
    sendPlayerCommand(playerRef.current, 'setVolume', [volume]);
  }, [volume]);

  useEffect(() => {
    const timer = window.setInterval(
      () => {
        sendPlayerCommand(playerRef.current, 'seekTo', [
          expectedPositionRef.current,
          true,
        ]);
        sendPlayerCommand(playerRef.current, 'setVolume', [volumeRef.current]);
      },
      Math.max(1, driftInterval) * 1000,
    );

    return () => window.clearInterval(timer);
  }, [driftInterval]);

  const embedUrl =
    `https://www.youtube-nocookie.com/embed/${videoId}` +
    `?enablejsapi=1&autoplay=1&playsinline=1&controls=1&rel=0&start=${startPosition}`;

  return (
    <>
      <Box
        style={{
          backgroundColor: '#000',
          height: '360px',
          overflow: 'hidden',
          width: '100%',
        }}
      >
        <iframe
          ref={playerRef}
          title="Synchronized YouTube player"
          src={embedUrl}
          allow="autoplay; encrypted-media; picture-in-picture"
          allowFullScreen
          onLoad={resync}
          style={{ border: 0, height: '100%', width: '100%' }}
        />
      </Box>
      <Button mt={1} icon="sync" onClick={resync}>
        Start / Resync
      </Button>
      <Box inline ml={1} color="label">
        Browser autoplay may require this button once per client session.
      </Box>
    </>
  );
};
