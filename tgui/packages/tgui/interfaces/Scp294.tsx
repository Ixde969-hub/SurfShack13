import { Button, Section } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Beaker, BeakerDisplay } from './common/BeakerDisplay';

type Data = {
  beaker: Beaker;
};

export const Scp294 = (props) => {
  const { act, data } = useBackend<Data>();
  const { beaker } = data;

  return (
    <Window width={390} height={315}>
      <Window.Content scrollable>
        <Section
          title="Recipient"
          buttons={
            beaker ? (
              <>
                <Button icon="keyboard" onClick={() => act('input')}>
                  Enter Liquid
                </Button>
                <Button icon="eject" onClick={() => act('eject')}>
                  Eject
                </Button>
              </>
            ) : (
              <Button icon="plus" onClick={() => act('makecup')}>
                Dispense Cup
              </Button>
            )
          }
        >
          <BeakerDisplay beaker={beaker} />
        </Section>
      </Window.Content>
    </Window>
  );
};
