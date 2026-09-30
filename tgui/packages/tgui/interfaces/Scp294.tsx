import { type ReactNode, useEffect, useState } from 'react';
import { Box, Input } from 'tgui-core/components';

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

const MAX_LENGTH = 40;

const OUTLINE = '#141018';

// Tiny 3x5 pixel font, so button labels are drawn as pixel art instead of text
const FONT: Record<string, string[]> = {
  A: ['010', '101', '111', '101', '101'],
  C: ['011', '100', '100', '100', '011'],
  E: ['111', '100', '110', '100', '111'],
  K: ['101', '101', '110', '101', '101'],
  O: ['010', '101', '101', '101', '010'],
  P: ['110', '101', '110', '100', '100'],
  R: ['110', '101', '110', '101', '101'],
  S: ['011', '100', '010', '001', '110'],
  T: ['111', '010', '010', '010', '010'],
  U: ['101', '101', '101', '101', '111'],
  '-': ['000', '000', '111', '000', '000'],
  '2': ['110', '001', '010', '100', '111'],
  '4': ['101', '101', '111', '001', '001'],
  '9': ['111', '101', '111', '001', '111'],
  ' ': ['000', '000', '000', '000', '000'],
};

const textWidth = (text: string) => text.length * 4 - 1;

/** Pixel-font text as rects, at (x, y) in pixel-grid units */
const PixelText = (props: {
  text: string;
  x: number;
  y: number;
  color: string;
  shadow?: string;
}) => {
  const { text, x, y, color, shadow } = props;
  const rects: ReactNode[] = [];
  text.split('').forEach((char, index) => {
    const glyph = FONT[char] || FONT[' '];
    glyph.forEach((row, gy) =>
      row.split('').forEach((bit, gx) => {
        if (bit !== '1') {
          return;
        }
        const px = x + index * 4 + gx;
        const py = y + gy;
        if (shadow) {
          rects.push(
            <rect
              key={`s${index}-${gx}-${gy}`}
              x={px}
              y={py + 1}
              width={1}
              height={1}
              fill={shadow}
            />,
          );
        }
        rects.push(
          <rect
            key={`t${index}-${gx}-${gy}`}
            x={px}
            y={py}
            width={1}
            height={1}
            fill={color}
          />,
        );
      }),
    );
  });
  return rects;
};

type ButtonColors = {
  light: string;
  face: string;
  dark: string;
};

const GREEN: ButtonColors = {
  light: '#8fe39a',
  face: '#4cbb5c',
  dark: '#2f8a3f',
};
const RED: ButtonColors = {
  light: '#f28a8a',
  face: '#d9474f',
  dark: '#a02a35',
};
const BLUE: ButtonColors = {
  light: '#9cc7f0',
  face: '#4f8fd0',
  dark: '#2f5f99',
};
const GREY: ButtonColors = {
  light: '#8c8c96',
  face: '#5c5c66',
  dark: '#3c3c44',
};

const BASE_FACE = '#b8b8d0';
const BASE_DARK = '#7a7a96';

/** Round, chunky pixel-art push button with a metal base plate */
const PixelButton = (props: {
  label: string;
  colors: ButtonColors;
  size?: number;
  scale?: number;
  disabled?: boolean;
  onClick: () => void;
}) => {
  const { label, size = 17, scale = 5, disabled, onClick } = props;
  const colors = disabled ? GREY : props.colors;
  const [pressed, setPressed] = useState(false);
  const depth = 3;
  const lift = pressed ? 1 : depth;
  const center = (size - 1) / 2;
  const radius = size / 2 - 0.3;

  const inside = (x: number, y: number) =>
    Math.hypot(x - center, y - center) <= radius;
  const edge = (x: number, y: number) =>
    inside(x, y) &&
    (!inside(x - 1, y) ||
      !inside(x + 1, y) ||
      !inside(x, y - 1) ||
      !inside(x, y + 1));

  const cells: ReactNode[] = [];
  // Base plate, drawn below the dome
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (!inside(x, y)) {
        continue;
      }
      cells.push(
        <rect
          key={`b${x}-${y}`}
          x={x}
          y={y + depth}
          width={1}
          height={1}
          fill={edge(x, y) ? OUTLINE : y > center ? BASE_DARK : BASE_FACE}
        />,
      );
    }
  }
  // Side of the dome between base and top, to make it look raised
  for (let step = lift - 1; step >= 0; step--) {
    for (let x = 0; x < size; x++) {
      for (let y = 0; y < size; y++) {
        if (inside(x, y) && y > center) {
          cells.push(
            <rect
              key={`d${step}-${x}-${y}`}
              x={x}
              y={y + depth - lift + step + 1}
              width={1}
              height={1}
              fill={edge(x, y) ? OUTLINE : colors.dark}
            />,
          );
        }
      }
    }
  }
  // Dome top
  const top = depth - lift;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (!inside(x, y)) {
        continue;
      }
      let fill = colors.face;
      const dist = Math.hypot(x - center, y - center);
      if (edge(x, y)) {
        fill = OUTLINE;
      } else if (dist > radius - 2.2 && x + y < center * 2 - 2) {
        fill = colors.light;
      } else if (dist > radius - 2.2 && x + y > center * 2 + 2) {
        fill = colors.dark;
      }
      cells.push(
        <rect
          key={`t${x}-${y}`}
          x={x}
          y={y + top}
          width={1}
          height={1}
          fill={fill}
        />,
      );
    }
  }

  const labelX = Math.round(center - textWidth(label) / 2 + 0.5);
  const labelY = Math.round(center - 2.5) + top;

  return (
    <div
      style={{
        cursor: disabled ? 'default' : 'pointer',
        display: 'inline-block',
        userSelect: 'none',
      }}
      onMouseDown={() => !disabled && setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      onClick={() => !disabled && onClick()}
    >
      <svg
        width={size * scale}
        height={(size + depth) * scale}
        viewBox={`0 0 ${size} ${size + depth}`}
        shapeRendering="crispEdges"
      >
        {cells}
        <PixelText
          text={label}
          x={labelX}
          y={labelY}
          color={disabled ? '#9a9aa4' : '#ffffff'}
          shadow={colors.dark}
        />
      </svg>
    </div>
  );
};

/** Pixel-art paper cup, filled with the liquid's colour */
const PixelCup = (props: { beaker: Beaker | null; color: string | null }) => {
  const { beaker, color } = props;
  const width = 14;
  const height = 17;
  const fill = beaker?.maxVolume
    ? Math.min(1, beaker.currentVolume / beaker.maxVolume)
    : 0;
  const liquidRows = Math.round(fill * (height - 3));

  // Cup narrows by one pixel on each side every 4 rows
  const rowInset = (y: number) => Math.floor(y / 5);

  const cells: ReactNode[] = [];
  for (let y = 0; y < height; y++) {
    const inset = rowInset(y);
    for (let x = inset; x < width - inset; x++) {
      const isEdge = x === inset || x === width - inset - 1 || y === height - 1;
      let fillColor: string;
      if (!beaker) {
        fillColor = isEdge || y === 0 ? '#4a4a55' : 'transparent';
      } else if (isEdge) {
        fillColor = OUTLINE;
      } else if (y <= 1) {
        fillColor = y === 0 ? OUTLINE : '#fffaf0';
      } else if (height - 1 - y <= liquidRows && color) {
        fillColor = color;
      } else if (x >= width - inset - 3) {
        fillColor = '#cfc6b3';
      } else {
        fillColor = '#efe9da';
      }
      if (fillColor === 'transparent') {
        continue;
      }
      cells.push(
        <rect
          key={`${x}-${y}`}
          x={x}
          y={y}
          width={1}
          height={1}
          fill={fillColor}
        />,
      );
      // Lighter surface line on top of the liquid
      if (
        beaker &&
        color &&
        !isEdge &&
        y > 1 &&
        height - 1 - y === liquidRows
      ) {
        cells.push(
          <rect
            key={`s${x}-${y}`}
            x={x}
            y={y}
            width={1}
            height={1}
            fill="#ffffff"
            opacity={0.4}
          />,
        );
      }
    }
  }

  return (
    <svg
      width={width * 7}
      height={height * 7}
      viewBox={`0 0 ${width} ${height}`}
      shapeRendering="crispEdges"
    >
      {cells}
    </svg>
  );
};

export const Scp294 = (props) => {
  const { act, data } = useBackend<Data>();
  const { beaker, amount, cup_color, status, status_error } = data;
  const [liquid, setLiquid] = useState('');
  const [pouring, setPouring] = useState(false);

  useEffect(() => {
    if (!pouring) {
      return;
    }
    const timer = setTimeout(() => setPouring(false), 1800);
    return () => clearTimeout(timer);
  }, [pouring]);

  const pour = () => {
    if (!beaker || !liquid.trim()) {
      return;
    }
    act('pour', { name: liquid });
    setPouring(true);
    setLiquid('');
  };

  return (
    <Window width={380} height={560}>
      <Window.Content>
        <Box
          style={{
            background: 'linear-gradient(#4a423a, #2a2521)',
            border: '4px solid #1b1714',
            borderRadius: '10px',
            boxShadow: 'inset 0 0 0 3px #6b6056',
            display: 'flex',
            flexDirection: 'column',
            height: '100%',
            padding: '12px',
          }}
        >
          <Box style={{ textAlign: 'center' }}>
            <svg
              width={textWidth('SCP-294') * 5 + 10}
              height={40}
              viewBox={`-1 -1 ${textWidth('SCP-294') + 2} 8`}
              shapeRendering="crispEdges"
            >
              <PixelText
                text="SCP-294"
                x={0}
                y={0}
                color="#e6c98f"
                shadow="#000"
              />
            </svg>
          </Box>

          <Box
            style={{
              background: '#0b1a10',
              border: '3px solid #111',
              borderRadius: '4px',
              boxShadow: 'inset 0 0 14px rgba(0, 0, 0, 0.9)',
              fontFamily: 'monospace',
              margin: '6px 0 10px',
              padding: '6px 8px',
            }}
          >
            <Box
              style={{
                color: status_error ? '#ff5a4d' : '#6dff8f',
                minHeight: '18px',
                textShadow: '0 0 4px currentColor',
              }}
            >
              {status || (beaker ? 'ENTER ANY LIQUID' : 'PLEASE TAKE A CUP')}
            </Box>
            <Input
              fluid
              autoFocus
              disabled={!beaker}
              maxLength={MAX_LENGTH}
              placeholder={beaker ? 'type a liquid, press enter...' : ''}
              value={liquid}
              onChange={(e, value) => setLiquid(value)}
              onEnter={() => pour()}
            />
          </Box>

          <Box
            style={{
              alignItems: 'center',
              background: 'linear-gradient(#0c0b0a, #1f1c19)',
              border: '4px solid #111',
              borderRadius: '6px',
              boxShadow: 'inset 0 6px 16px rgba(0, 0, 0, 0.9)',
              display: 'flex',
              flex: 1,
              flexDirection: 'column',
              justifyContent: 'flex-end',
              position: 'relative',
            }}
          >
            <Box
              style={{
                background: '#6b6056',
                border: '2px solid #111',
                borderTop: 'none',
                height: '14px',
                left: 'calc(50% - 14px)',
                position: 'absolute',
                top: 0,
                width: '28px',
              }}
            />
            {pouring && !!beaker && (
              <Box
                style={{
                  background: cup_color || '#8fd3ff',
                  bottom: '128px',
                  left: 'calc(50% - 3px)',
                  opacity: 0.85,
                  position: 'absolute',
                  top: '14px',
                  width: '6px',
                }}
              />
            )}
            <PixelCup beaker={beaker} color={cup_color} />
            <Box
              style={{
                background: '#3a3530',
                borderTop: '3px solid #111',
                height: '8px',
                marginTop: '2px',
                width: '100%',
              }}
            />
          </Box>

          <Box
            style={{
              color: '#d9c7a3',
              fontFamily: 'monospace',
              fontSize: '11px',
              minHeight: '16px',
              padding: '4px 0',
              textAlign: 'center',
            }}
          >
            {beaker
              ? beaker.contents?.length
                ? beaker.contents
                    .map((reagent) => `${reagent.volume}u ${reagent.name}`)
                    .join(', ')
                : `empty cup (${beaker.maxVolume}u)`
              : 'no cup'}
          </Box>

          <Box
            style={{
              alignItems: 'flex-end',
              display: 'flex',
              justifyContent: 'space-around',
            }}
          >
            <PixelButton
              label="CUP"
              colors={GREEN}
              disabled={!!beaker}
              onClick={() => act('makecup')}
            />
            <PixelButton
              label="POUR"
              colors={RED}
              size={21}
              scale={5}
              disabled={!beaker || !liquid.trim()}
              onClick={pour}
            />
            <PixelButton
              label="TAKE"
              colors={BLUE}
              disabled={!beaker}
              onClick={() => act('take_cup')}
            />
          </Box>
          <Box
            style={{
              color: '#8a7d6e',
              fontFamily: 'monospace',
              fontSize: '10px',
              paddingTop: '2px',
              textAlign: 'center',
            }}
          >
            {amount}u per pour
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};
