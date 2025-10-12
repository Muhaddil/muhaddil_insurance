interface DebugEvent {
  action: string;
  data: any;
}

const developmentMode = false;

export const debugData = (events: DebugEvent[], timer = 1000): void => {
  if (developmentMode) {
    events.forEach((event, index) => {
      setTimeout(() => {
        window.dispatchEvent(
          new MessageEvent("message", {
            data: {
              action: event.action,
              ...event.data,
            },
          }),
        );
      }, timer * index);
    });
  }
};
