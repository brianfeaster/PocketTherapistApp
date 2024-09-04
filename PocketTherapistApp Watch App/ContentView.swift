//
//  ContentView.swift
//  PocketTherapistApp Watch App
//
//  Created by Brian Feaster on 9/4/24.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var bpm = 60;
    @State private var state = 0;
    @State private var toggleBPMDescription = true;
    @State private var breathingStep = 0;

    let breathingCountInitial = 5
    let breathingDelay = DispatchTimeInterval.seconds(3)
    let rateNormal = 100
    let rateHigh = 200

    var body: some View {
        VStack{
            header
            Spacer()
            main
            Spacer()
            Button(action: bpmUpdateForce)
                {Text("\(bpm) BPM")}
                .fixedSize(horizontal: true, vertical: true)
                .foregroundColor(.gray)
        }
        .multilineTextAlignment(.center)
        .onAppear(perform: bpmUpdateBackgroundLoop)
    }

    var header: some View {
        VStack{
            Text(bpm2heart())
            if toggleBPMDescription {
                bpm < rateNormal ? Text("Heart rate normal.")
                : bpm < rateHigh ? Text("Heart rate high.")
                : Text("Heat rate bad.")
            } else {
                Text(" ")
            }
        }
        .foregroundColor(bpm2color())
        .onTapGesture{toggleBPMDescription.toggle()}
    }

    var main: some View {
        VStack {
            switch state {
            case 0 : mainMonitor
            default: mainBreathing
            }
        }
    }

    var mainMonitor: some View {
        VStack{
            if rateNormal <= bpm && bpm < rateHigh {
                Button(action: breathingStartState)
                {Text("Begin breathing exercise...")}
            }
        }
    }

    var mainBreathing: some View {
        VStack{
            if 1==breathingStep {
                Button(action: breathingNextState)
                {Text("\(breathingStep) You Are Amazing")}
            } else if 1==breathingStep%2 {
                Button(action: breathingNextState)
                {Text("\(breathingStep) Inhale...")}
            } else {
                Button(action: breathingNextState)
                {Text("\(breathingStep) Exhale...")}
            }
        }
    }

    //

    private func bpm2heart () -> String {
        bpm<rateNormal ? "💚💚"
        : bpm<rateHigh ? "💛💛"
        : "💔💔"
    }

    private func bpm2color() -> Color {
        {Color.init(red: $0.0, green: $0.1, blue: $0.2)}(
            self.bpm < rateNormal ? (0.2, 0.6, 0.2) // greenish
            : self.bpm < rateHigh ? (0.6, 0.6, 0.2) // yellowish
            : (0.8, 0.2, 0.2) // redish
        )
    }

    @State private var BreathingStepEnd :DispatchTime = .now();
    @State private var breathingLoopId = 0
    private func breathingStartState () {
        state = 1
        breathingStep = breathingCountInitial
        BreathingStepEnd = .now() + breathingDelay
        breathingLoopId += 1
        let loopId = breathingLoopId
        var loop = {}
        loop = {
            if 1 != state || loopId != breathingLoopId { return }
            if BreathingStepEnd <= .now() { breathingNextState() }
            DispatchQueue.main.asyncAfter(deadline: BreathingStepEnd, execute: loop)
        }
        loop()
    }

    private func breathingNextState () {
        breathingStep = breathingStep==2 && rateNormal<=bpm
            ? 0 // skip affirmation
            : breathingStep - 1
        if breathingStep <= 0 {
            state = 0
        } else {
            BreathingStepEnd = .now() + breathingDelay
        }
    }

    private func bpmUpdateBackgroundLoop () {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            bpmUpdateBackgroundLoop()
            if (60 < bpm) { bpm-=1 }
        }
    }

    private func bpmUpdateForce() {
        let date = Date()
        let predicate = HKQuery.predicateForSamples(
            withStart: date.addingTimeInterval(-60),
            end: date,
            options: .strictEndDate)
        let query = HKStatisticsQuery(
            quantityType: .quantityType(forIdentifier: .heartRate)!,
            quantitySamplePredicate: predicate,
            options: .discreteAverage) { _, result, _ in
                guard
                    let result = result,
                    let quantity = result.averageQuantity()
                else {
                    self.bpm = Int.random(in: 0..<250)
                    return
                }
                self.bpm = Int(quantity.doubleValue(for: HKUnit(from: "count/min")))
            }
        HKHealthStore().execute(query)
    }
}

struct ContentViewTemplate: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("PocketTherapist iWatch")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
