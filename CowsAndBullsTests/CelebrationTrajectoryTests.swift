//
//  CelebrationTrajectoryTests.swift
//  CowsAndBullsTests
//
//  Created by Codex on 2026. 03. 18..
//

import Testing
import Foundation
@testable import Cows___Bulls

struct CelebrationTrajectoryTests {
    @Test("Random trajectory stays within configured Y bands")
    func randomTrajectoryStaysWithinBands() {
        var generator = SeededGenerator(state: 1)
        let trajectory = CelebrationTrajectory.random(
            panelSize: CGSize(width: 1200, height: 800),
            centerPoint: CGPoint(x: 600, y: 320),
            cowSize: 180,
            using: &generator
        )

        #expect(CelebrationTrajectory.startYRange.contains(trajectory.startYRatio))
        #expect(CelebrationTrajectory.endYRange.contains(trajectory.endYRatio))
    }

    @Test("Trajectory passes through center point at alert progress in both directions")
    func trajectoryPassesThroughCenterPoint() {
        let panelSize = CGSize(width: 1200, height: 800)
        let centerPoint = CGPoint(x: 620, y: 340)
        let cowSize: CGFloat = 180
        let centerProgress = CGFloat(2.2 / 4.5)

        let leftToRight = CelebrationTrajectory(
            panelSize: panelSize,
            centerPoint: centerPoint,
            cowSize: cowSize,
            direction: .leftToRight,
            startYRatio: 0.90,
            endYRatio: 0.12
        )

        let rightToLeft = CelebrationTrajectory(
            panelSize: panelSize,
            centerPoint: centerPoint,
            cowSize: cowSize,
            direction: .rightToLeft,
            startYRatio: 0.88,
            endYRatio: 0.20
        )

        #expect(leftToRight.position(for: centerProgress, centerProgress: centerProgress) == centerPoint)
        #expect(rightToLeft.position(for: centerProgress, centerProgress: centerProgress) == centerPoint)
        #expect(leftToRight.startX < leftToRight.endX)
        #expect(rightToLeft.startX > rightToLeft.endX)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1
        return state
    }
}
